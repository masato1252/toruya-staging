# frozen_string_literal: true

module Subscriptions
  class ManualCharge < ActiveInteraction::Base
    object :subscription
    object :plan
    integer :rank
    string :authorize_token
    string :payment_intent_id, default: nil

    validate :validate_plan_downgraade

    def execute
      user = subscription.user
      failed_charge_data = nil

      # トランザクション内でロックを取得
      ActiveRecord::Base.transaction do
        subscription.with_lock do
          store_customer_outcome = Payments::StoreStripeCustomer.run(
            user: user, 
            authorize_token: authorize_token, 
            payment_intent_id: payment_intent_id
          )
          
          unless store_customer_outcome.valid?
            # StoreStripeCustomerが失敗した場合もchargeレコードを作成
            charge_amount_for_error = begin
              new_plan_price, charging_rank = compose(Plans::Price, user: user, plan: plan, rank: rank)
              residual_value = compose(Subscriptions::ResidualValue, user: user)
              if user.subscription.in_paid_plan && (last_charge = user.subscription_charges.last_plan_charged)
                new_plan_price = new_plan_price * Rational(last_charge.expired_date - Subscription.today, last_charge.expired_date - last_charge.charge_date)
              end
              amount = new_plan_price - residual_value
              amount.positive? ? amount : new_plan_price
            rescue => e
              Money.new(0, user.currency || "JPY")
            end
            
            # エラー詳細を取得
            user_error = store_customer_outcome.errors.details[:user]&.first || {}
            customer_error = store_customer_outcome.errors.details[:customer]&.first || {}
            
            # エラータイプとStripeエラー情報を取得
            error_type = user_error[:error] || customer_error[:error]
            raw_stripe_message = user_error[:stripe_error_message] || customer_error[:stripe_error_message]
            stripe_error_code = user_error[:stripe_error_code] || customer_error[:stripe_error_code]
            
            # ユーザー向けメッセージを生成（full_messagesは使わない）
            user_friendly_message = if error_type == :auth_failed
              I18n.t("active_interaction.errors.models.payments/store_stripe_customer.attributes.user.auth_failed")
            elsif error_type == :processor_failed
              I18n.t("active_interaction.errors.models.payments/store_stripe_customer.attributes.user.processor_failed")
            elsif error_type == :requires_action
              I18n.t("active_interaction.errors.models.payments/store_stripe_customer.attributes.user.requires_action")
            else
              store_customer_outcome.errors.full_messages.join(', ')
            end
            
            # エラーメッセージにはユーザー向けメッセージと生のStripeエラーを両方含める
            combined_error_message = if raw_stripe_message.present?
              error_details = "#{raw_stripe_message}"
              error_details += " (code: #{stripe_error_code})" if stripe_error_code.present?
              "#{user_friendly_message} | Raw error: #{error_details}"
            else
              user_friendly_message
            end
            
            failed_charge_data = {
              user_id: user.id,
              plan_id: plan.id,
              rank: rank,
              amount_cents: charge_amount_for_error.cents,
              amount_currency: charge_amount_for_error.currency.iso_code,
              charge_date: Subscription.today,
              manual: true,
              order_id: OrderId.generate,
              state: 'auth_failed',
              error_message: combined_error_message
            }
            
            errors.merge!(store_customer_outcome.errors)
            raise ActiveRecord::Rollback
          end

          # 新プランの料金を取得
          new_plan_price, charging_rank = compose(Plans::Price, user: user, plan: plan, rank: rank)

          # 既存プランの残存価値を取得（新規：0円、既存：残存価値）
          residual_value = compose(Subscriptions::ResidualValue, user: user)

          # アップグレード時、新プランの料金を残りの契約期間で日割り計算
          if user.subscription.in_paid_plan && (last_charge = user.subscription_charges.last_plan_charged)
            new_plan_price = new_plan_price * Rational(last_charge.expired_date - Subscription.today, last_charge.expired_date - last_charge.charge_date)
          end

          charge_amount = new_plan_price - residual_value
          unless charge_amount.positive?
            charge_amount = new_plan_price
          end

          charge_outcome = Subscriptions::Charge.run(
            user: user,
            plan: plan,
            rank: charging_rank,
            manual: true,
            charge_amount: charge_amount,
            payment_intent_id: payment_intent_id,
            payment_method_id: authorize_token
          )

          if charge_outcome.valid?
            charge = charge_outcome.result
            
            # 決済成功時のみsubscriptionを更新
            subscription.plan = plan
            subscription.rank = charging_rank
            subscription.next_plan = nil
            # 新規契約時のみrecurring_dayを設定（アップグレード時は既存のrecurring_dayを保持）
            unless user.subscription.in_paid_plan && user.subscription_charges.last_plan_charged
              subscription.set_recurring_day
            end
            subscription.set_expire_date
            subscription.save!

            # 成功時のみcharge.detailsを作成
            charge.expired_date = subscription.expired_date
            charge.details = {
              shop_ids: user.shop_ids,
              type: plan.business_level? ? SubscriptionCharge::TYPES[:business_member_sign_up] : SubscriptionCharge::TYPES[:plan_subscruption],
              user_name: user.name,
              user_email: user.email,
              pure_plan_amount: compose(Plans::Price, user: user, plan: plan)[0].format,
              plan_amount: compose(Plans::Price, user: user, plan: plan)[0].format,
              plan_name: plan.name,
              charge_amount: charge_amount.format,
              residual_value: residual_value.format,
              rank: charging_rank
            }
            charge.save!

            Notifiers::Users::Subscriptions::ChargeSuccessfully.run(receiver: subscription.user, user: subscription.user)
          else
            # 決済失敗時、chargeの情報を保持（トランザクション外で再保存するため）
            charge = charge_outcome.result
            if charge
              failed_charge_data = {
                user_id: user.id,
                plan_id: plan.id,
                rank: charging_rank,
                amount_cents: charge_amount.cents,
                amount_currency: charge_amount.currency.iso_code,
                charge_date: charge.charge_date,
                manual: true,
                order_id: charge.order_id,
                state: charge.state,
                stripe_charge_details: charge.stripe_charge_details,
                error_message: charge.error_message
              }
            end
            
            # エラーをマージしてロールバック
            errors.merge!(charge_outcome.errors)
            raise ActiveRecord::Rollback
          end
        end
      end
      
      # トランザクション外でfailed chargeを再保存（ロールバックの影響を受けない）
      if failed_charge_data
        begin
          SubscriptionCharge.create!(failed_charge_data)
        rescue => e
          Rollbar.error("Failed to save charge record", error: e.message, charge_data: failed_charge_data)
        end
      end
    end

    private

    def validate_plan_downgraade
      if subscription.current_plan.downgrade?(plan)
        # XXX: Downgrade behavior shouldn't happen manually,
        # it should be executed until the expired date.
        errors.add(:plan, :unable_to_downgrade_manually)
      end
    end
  end
end
