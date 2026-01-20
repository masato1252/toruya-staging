# frozen_string_literal: true

require "slack_client"
require "order_id"

module Subscriptions
  class Charge < ActiveInteraction::Base
    include StripePaymentMethodHandler
    object :user
    object :plan
    boolean :manual
    object :charge_amount, class: Money, default: nil
    integer :rank, default: nil
    string :charge_description, default: nil
    string :payment_intent_id, default: nil
    string :payment_method_id, default: nil

    def execute
      I18n.with_locale(user.locale) do
        order_id = OrderId.generate
        # XXX: business plan charged manually means, it is a registration charge, user need to pay extra signup fee
        amount, charging_rank =
        if charge_amount && rank
          [charge_amount, rank]
        else
          compose(Plans::Price, user: user, plan: plan, rank: rank)
        end

        description = charge_description || plan.level

        # chargeレコードを作成（まだ保存しない）
        charge = user.subscription_charges.build(
          plan: plan,
          rank: charging_rank,
          amount: amount,
          charge_date: Subscription.today,
          manual: manual,
          order_id: order_id
        )

        begin
          payment_intent = if payment_intent_id.present?
            Stripe::PaymentIntent.retrieve(payment_intent_id)
          else
            create_payment_intent(amount, description, charge, charging_rank, order_id)
          end

          # If PaymentIntent creation fails (e.g. recurring charge has no payment method)
          if payment_intent.nil?
            user_friendly_message = I18n.t("active_interaction.errors.models.plan.attributes.base.no_payment_method")
            raw_error = errors.full_messages.join(', ')
            charge.error_message = "#{user_friendly_message} | Raw error: Failed to create payment intent - #{raw_error}"
            charge.auth_failed!
            charge.save!
            errors.add(:plan, :no_payment_method)
            
            Rollbar.error("Payment intent creation failed", user_id: user.id, errors: errors.full_messages)
            
            return charge
          end

          case payment_intent.status
          when "succeeded"
            # 決済成功時のみchargeを保存
            charge.stripe_charge_details = payment_intent.as_json
            charge.completed!
            charge.save!

            if Rails.configuration.x.env.production?
              if user.subscription_charges.finished.count == 1
                referral = Referral.find_by(referrer: user)

                text = if referral
                  referral.update(state: :active)
                  "💭 `🎉 user_id: #{user.id} from #{referral.referee.referral_token}` #{"<#{Rails.application.routes.url_helpers.admin_chats_url(user_id: user.id)}|chat link>"} new Paid user"
                else
                  "💭 `🎉 user_id: #{user.id}` #{"<#{Rails.application.routes.url_helpers.admin_chats_url(user_id: user.id)}|chat link>"} new Paid user"
                end

                SlackClient.send(channel: 'new_paid_users', text: text)
              elsif manual && plan.premium_level?
                text = "💭 `🎉 user_id: #{user.id}` #{"<#{Rails.application.routes.url_helpers.admin_chats_url(user_id: user.id)}|chat link>"} user upgraded"
                SlackClient.send(channel: 'new_paid_users', text: text)
              else
                charge_type = manual ? "Manual" : "Recurring"
                SlackClient.send(channel: 'sayhi', text: "[OK] 🎉#{charge_type} Stripe charge user: #{user.id} 💰")
              end
            end
          when "requires_payment_method", "requires_source", "requires_confirmation", "requires_action", "processing", "requires_capture", "requires_source_action"
            # 3DS認証が必要な場合、chargeは保存するがdetailsは作成しない（ManualChargeで作成される）
            charge.stripe_charge_details = payment_intent.as_json
            user_friendly_message = I18n.t("active_interaction.errors.models.plan.attributes.base.requires_payment_method")
            # ユーザー向けメッセージと生のエラーを両方記録
            error_details = "Payment intent status: #{payment_intent.status}"
            error_details += ", last_payment_error: #{payment_intent.last_payment_error&.dig('message')}" if payment_intent.last_payment_error.present?
            charge.error_message = "#{user_friendly_message} | Raw error: #{error_details}"
            charge.save!
            errors.add(:plan, :requires_payment_method, 
              client_secret: payment_intent.client_secret, 
              payment_intent_id: payment_intent.id,
              user_message: user_friendly_message
            )
          when "canceled"
            # 決済失敗時もchargeを保存（追跡のため）
            charge.stripe_charge_details = payment_intent.as_json
            user_friendly_message = I18n.t("active_interaction.errors.models.plan.attributes.base.canceled")
            # ユーザー向けメッセージと生のエラーを両方記録
            error_details = "Cancellation reason: #{payment_intent.cancellation_reason || 'not specified'}"
            error_details += ", last_payment_error: #{payment_intent.last_payment_error&.dig('message')}" if payment_intent.last_payment_error.present?
            charge.error_message = "#{user_friendly_message} | Raw error: #{error_details}"
            charge.auth_failed!
            charge.save!
            errors.add(:plan, :canceled, client_secret: payment_intent.client_secret)
          else
            # その他の失敗ステータス時もchargeを保存
            charge.stripe_charge_details = payment_intent.as_json
            user_friendly_message = I18n.t("active_interaction.errors.models.plan.attributes.base.auth_failed")
            # ユーザー向けメッセージと生のエラーを両方記録
            error_details = "Payment intent failed with status: #{payment_intent.status}"
            error_details += ", last_payment_error: #{payment_intent.last_payment_error&.dig('message')}" if payment_intent.last_payment_error.present?
            charge.error_message = "#{user_friendly_message} | Raw error: #{error_details}"
            charge.auth_failed!
            charge.save!
            
            errors.add(:plan, :auth_failed, payment_intent_id: payment_intent.id)

            handle_charge_failed(charge)

            if Rails.configuration.x.env.production?
              SlackClient.send(channel: 'sayhi', text: "[Failed] Subscription Stripe charge user: #{user.id}, payment intent status: #{payment_intent.status}")
              Rollbar.error("Payment intent failed", status: payment_intent.status, user_id: user.id, stripe_charge: payment_intent.as_json)
            end
          end
        rescue Stripe::CardError => error
          # 決済失敗時もchargeを保存（追跡のため）
          stripe_error = error.json_body&.dig(:error) || {}
          raw_error_message = stripe_error[:message] || error.message
          user_friendly_message = I18n.t("active_interaction.errors.models.plan.attributes.base.auth_failed")
          
          charge.stripe_charge_details = stripe_error
          # ユーザー向けメッセージと生のエラーを両方記録
          charge.error_message = "#{user_friendly_message} | Raw error: #{raw_error_message} (code: #{stripe_error[:code]})"
          charge.auth_failed!
          charge.save!
          
          errors.add(:plan, :auth_failed, 
            stripe_error_code: stripe_error[:code],
            stripe_error_message: raw_error_message,
            user_message: user_friendly_message
          )

          handle_charge_failed(charge)

          if Rails.configuration.x.env.production?
            SlackClient.send(channel: 'sayhi', text: "[Failed] Subscription Stripe charge user: #{user.id}, #{error}")
            Rollbar.error(error, user_id: user.id, stripe_charge: stripe_error)
          end
        rescue Stripe::StripeError => error
          # 決済失敗時もchargeを保存（追跡のため）
          stripe_error = error.json_body&.dig(:error) || {}
          raw_error_message = stripe_error[:message] || error.message
          user_friendly_message = I18n.t("active_interaction.errors.models.plan.attributes.base.processor_failed")
          
          charge.stripe_charge_details = stripe_error
          # ユーザー向けメッセージと生のエラーを両方記録
          charge.error_message = "#{user_friendly_message} | Raw error: #{raw_error_message} (code: #{stripe_error[:code]})"
          charge.processor_failed!
          charge.save!
          
          errors.add(:plan, :processor_failed,
            stripe_error_code: stripe_error[:code],
            stripe_error_message: raw_error_message,
            user_message: user_friendly_message
          )

          handle_charge_failed(charge)

          if Rails.configuration.x.env.production?
            SlackClient.send(channel: 'sayhi', text: "[Failed] Subscription Stripe charge user: #{user.id}, #{error}")
            Rollbar.error(error, user_id: user.id, stripe_charge: stripe_error)
          end
        rescue => e
          # その他のエラーもchargeを保存
          user_friendly_message = I18n.t("active_interaction.errors.models.plan.attributes.base.something_wrong")
          # ユーザー向けメッセージと生のエラーを両方記録
          charge.error_message = "#{user_friendly_message} | Raw error: #{e.class} - #{e.message}"
          charge.auth_failed!
          charge.save!
          
          errors.add(:plan, :something_wrong)
          
          if Rails.configuration.x.env.production?
            Rollbar.error(e, user_id: user.id, charge_id: charge.id)
          end
        end

        # XXX: Put the fee and referral behviors here is because the of plans changes behaviors
        # might not happen right away, it might happend in next charge,
        # so Subscriptions::Charge is the place, every charge hehavior will called.
        # So put it here to handle all kind of charge or plan changes.
        # if charge.completed? && referral = Referral.enabled.find_by(referrer: user)
        #   compose(Referrals::ReferrerCharged, charge: charge, referral: referral, plan: plan)
        # end

        charge
      end
    end

    private

    def create_payment_intent(amount, description, charge, charging_rank, order_id)
      # Check if user has a stripe customer ID
      stripe_customer_id = user.subscription&.stripe_customer_id
      if stripe_customer_id.blank?
        errors.add(:plan, :no_stripe_customer)
        return nil
      end

      if manual
        # Manual payment - get selected payment method using shared logic
        selected_payment_method = get_selected_payment_method(stripe_customer_id, payment_method_id)

        if selected_payment_method.nil?
          errors.add(:plan, :stripe_customer_not_found)
          if Rails.configuration.x.env.production?
            Rollbar.error("No payment method available", user_id: user.id, stripe_customer_id: stripe_customer_id)
          end
          return nil
        end

        payment_intent_params = {
          amount: amount.fractional * amount.currency.default_subunit_to_unit,
          currency: amount.currency.iso_code,
          customer: stripe_customer_id,
          description: description,
          statement_descriptor: "Toruya #{description}",
          metadata: {
            level: plan.level,
            rank: charging_rank,
            user_id: user.id,
            order_id: order_id
          },
          setup_future_usage: 'off_session',  # Save payment method for future use
          confirmation_method: 'automatic',      # If 3DS is needed, automatically return requires_action status
          capture_method: 'automatic',        # Automatically capture payment
          payment_method_types: ['card']
        }

        # Add payment method and confirm if available
        if selected_payment_method.present?
          payment_intent_params[:payment_method] = selected_payment_method
          payment_intent_params[:confirm] = true
        end

        Stripe::PaymentIntent.create(payment_intent_params)
      else
        # Automatic recurring charge - get selected payment method using shared logic
        selected_payment_method = get_selected_payment_method(stripe_customer_id, nil)

        if selected_payment_method.nil?
          errors.add(:plan, :no_payment_method)
          if Rails.configuration.x.env.production?
            Rollbar.error("No payment method available for recurring charge", user_id: user.id, stripe_customer_id: stripe_customer_id)
          end
          return nil
        end

        Stripe::PaymentIntent.create({
          amount: amount.fractional * amount.currency.default_subunit_to_unit,
          currency: amount.currency.iso_code,
          customer: stripe_customer_id,
          payment_method: selected_payment_method,  # Use selected payment method
          description: description,
          statement_descriptor: "Toruya #{description}",
          metadata: {
            level: plan.level,
            rank: charging_rank,
            user_id: user.id,
            order_id: order_id,
            recurring: true  # Mark as recurring charge
          },
          off_session: true,      # Offline payment, no user interaction needed
          confirm: true,          # Immediately attempt to confirm payment
          payment_method_types: ['card']
        })
      end
    end

    def handle_charge_failed(charge)
      unless manual
        # chargeが保存されている場合のみ通知を送信
        if charge.persisted?
          Notifiers::Users::Subscriptions::ChargeFailed.run(
            receiver: user,
            user: user,
            subscription_charge: charge
          )
        end

        # If the customer's plan is not free, and the last successful charge was more than 2 months ago, and this charge failed, downgrade the plan to free
        if user.subscription.charge_required && user.subscription_charges.last_completed&.charge_date && user.subscription_charges.last_completed.charge_date < 2.months.ago
          user.subscription.update(plan: Plan.free_level.take)
        end
      end
    end
  end
end
