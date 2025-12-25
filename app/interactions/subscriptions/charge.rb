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
            errors.add(:plan, :no_payment_method)
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
            charge.save!
            errors.add(:plan, :requires_payment_method, client_secret: payment_intent.client_secret, payment_intent_id: payment_intent.id)
          when "canceled"
            # 決済失敗時はchargeを保存しない（ロールバックされる）
            errors.add(:plan, :canceled, client_secret: payment_intent.client_secret)
          else
            Rollbar.error("Payment intent failed", status: payment_intent.status, user_id: user.id, stripe_charge: payment_intent.as_json)
            # 決済失敗時はchargeを保存しない（ロールバックされる）
            errors.add(:plan, :auth_failed, payment_intent_id: payment_intent.id)

            handle_charge_failed(charge)

            if Rails.configuration.x.env.production?
              SlackClient.send(channel: 'sayhi', text: "[Failed] Subscription Stripe charge user: #{user.id}, payment intent status: #{payment_intent.status}")
              Rollbar.error("Payment intent failed", user_id: user.id, stripe_charge: payment_intent.as_json)
            end
          end
        rescue Stripe::CardError => error
          # 決済失敗時はchargeを保存しない（ロールバックされる）
          stripe_error = error.json_body[:error] || {}
          errors.add(:plan, :auth_failed, 
            stripe_error_code: stripe_error[:code],
            stripe_error_message: stripe_error[:message] || error.message
          )

          handle_charge_failed(charge)

          if Rails.configuration.x.env.production?
            SlackClient.send(channel: 'sayhi', text: "[Failed] Subscription Stripe charge user: #{user.id}, #{error}")
            Rollbar.error(error, user_id: user.id, stripe_charge: error.json_body[:error])
          end
        rescue Stripe::StripeError => error
          # 決済失敗時はchargeを保存しない（ロールバックされる）
          stripe_error = error.json_body[:error] || {}
          errors.add(:plan, :processor_failed,
            stripe_error_code: stripe_error[:code],
            stripe_error_message: stripe_error[:message] || error.message
          )

          handle_charge_failed(charge)

          if Rails.configuration.x.env.production?
            SlackClient.send(channel: 'sayhi', text: "[Failed] Subscription Stripe charge user: #{user.id}, #{error}")
            Rollbar.error(error, user_id: user.id, stripe_charge: error.json_body[:error])
          end
        rescue => e
          Rollbar.error(e)
          errors.add(:plan, :something_wrong)
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
          Rollbar.error("No payment method available", user_id: user.id, stripe_customer_id: stripe_customer_id)
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
          Rollbar.error("No payment method available for recurring charge", user_id: user.id, stripe_customer_id: stripe_customer_id)
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
