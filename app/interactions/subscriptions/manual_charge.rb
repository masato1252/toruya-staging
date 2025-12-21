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

      subscription.with_lock do
        Payments::StoreStripeCustomer.run(user: user, authorize_token: authorize_token, payment_intent_id: payment_intent_id)

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
          # Rollbar.warning(
          #   "Unexpected charge amount",
          #   user_id: user.id,
          #   plan_id: plan.id,
          #   rank: charging_rank,
          #   new_plan_price: new_plan_price.format,
          #   residual_value: residual_value.format,
          #   authorize_token: authorize_token
          # )

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
          subscription.plan = plan
          subscription.rank = charging_rank
          subscription.next_plan = nil
          # 新規契約時のみrecurring_dayを設定（アップグレード時は既存のrecurring_dayを保持）
          unless user.subscription.in_paid_plan && user.subscription_charges.last_plan_charged
            subscription.set_recurring_day
          end
          subscription.set_expire_date
          subscription.save!

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
          errors.merge!(charge_outcome.errors)
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
