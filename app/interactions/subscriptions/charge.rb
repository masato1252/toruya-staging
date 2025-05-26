# frozen_string_literal: true

require "slack_client"
require "order_id"

module Subscriptions
  class Charge < ActiveInteraction::Base
    object :user
    object :plan
    boolean :manual
    object :charge_amount, class: Money, default: nil
    integer :rank, default: nil
    string :charge_description, default: nil
    string :payment_intent_id, default: nil

    def execute
      # SubscriptionCharge.transaction do
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

          charge = user.subscription_charges.create!(
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

            # If PaymentIntent creation fails (e.g. recurring charge has no payment method), return charge directly
            return charge if payment_intent.nil?

            case payment_intent.status
            when "succeeded"
              charge.stripe_charge_details = payment_intent.as_json
              charge.completed!

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
              charge.stripe_charge_details = payment_intent.as_json
              charge.save!
              errors.add(:plan, :requires_payment_method, client_secret: payment_intent.client_secret)
            when "canceled"
              charge.stripe_charge_details = payment_intent.as_json
              charge.auth_failed!
              charge.save!
              errors.add(:plan, :canceled, client_secret: payment_intent.client_secret)
            else
              Rollbar.error("Payment intent failed", status: payment_intent.status, toruya_charge: charge.id, stripe_charge: payment_intent.as_json)
              charge.stripe_charge_details = payment_intent.as_json
              charge.auth_failed!
              charge.save!
              errors.add(:plan, :auth_failed, payment_intent_id: payment_intent.id)

              unless manual
                Notifiers::Users::Subscriptions::ChargeFailed.run(
                  receiver: user,
                  user: user,
                  subscription_charge: charge
                )
              end

              if Rails.configuration.x.env.production?
                SlackClient.send(channel: 'sayhi', text: "[Failed] Subscription Stripe charge user: #{user.id}, payment intent status: #{payment_intent.status}")
                Rollbar.error("Payment intent failed", toruya_charge: charge.id, stripe_charge: payment_intent.as_json)
              end
            end
          rescue Stripe::CardError => error
            charge.stripe_charge_details = error.json_body[:error]
            charge.auth_failed!
            errors.add(:plan, :auth_failed)

            unless manual
              Notifiers::Users::Subscriptions::ChargeFailed.run(
                receiver: user,
                user: user,
                subscription_charge: charge
              )
            end

            if Rails.configuration.x.env.production?
              SlackClient.send(channel: 'sayhi', text: "[Failed] Subscription Stripe charge user: #{user.id}, #{error}")
              Rollbar.error(error, toruya_charge: charge.id, stripe_charge: error.json_body[:error])
            end
          rescue Stripe::StripeError => error
            charge.stripe_charge_details = error.json_body[:error]
            charge.processor_failed!
            errors.add(:plan, :processor_failed)

            unless manual
              Notifiers::Users::Subscriptions::ChargeFailed.run(
                receiver: user,
                user: user,
                subscription_charge: charge
              )
            end

            if Rails.configuration.x.env.production?
              SlackClient.send(channel: 'sayhi', text: "[Failed] Subscription Stripe charge user: #{user.id}, #{error}")
              Rollbar.error(error, toruya_charge: charge.id, stripe_charge: error.json_body[:error])
            end
          rescue => e
            Rollbar.error(e)
            errors.add(:plan, :something_wrong)
          end

          # XXX: Put the fee and referral behviors here is because the of plans changes behaviors
          # might not happen right away, it might happend in next charge,
          # so Subscriptions::Charge is the place, every charge hehavior will called.
          # So put it here to handle all kind of charge or plan changes.
          if charge.completed? && referral = Referral.enabled.find_by(referrer: user)
            compose(Referrals::ReferrerCharged, charge: charge, referral: referral, plan: plan)
          end

          charge
        end
      # end
    end

    private

    def create_payment_intent(amount, description, charge, charging_rank, order_id)
      # Check if user has a stripe customer ID
      stripe_customer_id = user.subscription&.stripe_customer_id
      if stripe_customer_id.blank?
        charge.auth_failed!
        errors.add(:plan, :no_stripe_customer)
        return nil
      end

      if manual
        # Manual payment - get customer's default payment method
        begin
          customer = Stripe::Customer.retrieve(stripe_customer_id)
          default_payment_method = customer.invoice_settings&.default_payment_method ||
                                   get_latest_payment_method(customer.id)
        rescue Stripe::StripeError => e
          charge.auth_failed!
          errors.add(:plan, :stripe_customer_not_found)
          Rollbar.error(e, user_id: user.id, stripe_customer_id: stripe_customer_id)
          return nil
        end

        payment_intent_params = {
          amount: amount.fractional * amount.currency.default_subunit_to_unit,
          currency: amount.currency.iso_code,
          customer: stripe_customer_id,
          description: description,
          statement_descriptor: "Toruya #{description}",
          metadata: {
            charge_id: charge.id,
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
        if default_payment_method.present?
          payment_intent_params[:payment_method] = default_payment_method
          payment_intent_params[:confirm] = true
        end

        Stripe::PaymentIntent.create(payment_intent_params)
      else
        # Automatic recurring charge - use saved payment method
        begin
          customer = Stripe::Customer.retrieve(stripe_customer_id)
          default_payment_method = customer.invoice_settings&.default_payment_method ||
                                   get_latest_payment_method(customer.id)
        rescue Stripe::StripeError => e
          charge.auth_failed!
          errors.add(:plan, :stripe_customer_not_found)
          Rollbar.error(e, user_id: user.id, stripe_customer_id: stripe_customer_id)
          return nil
        end

        if default_payment_method.nil?
          charge.auth_failed!
          errors.add(:plan, :no_payment_method)
          return nil
        end

        Stripe::PaymentIntent.create({
          amount: amount.fractional * amount.currency.default_subunit_to_unit,
          currency: amount.currency.iso_code,
          customer: stripe_customer_id,
          payment_method: default_payment_method,  # Use saved payment method
          description: description,
          statement_descriptor: "Toruya #{description}",
          metadata: {
            charge_id: charge.id,
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

    def get_latest_payment_method(customer_id)
      begin
        payment_methods = Stripe::PaymentMethod.list({
          customer: customer_id,
          type: 'card',
          limit: 1
        })
        payment_methods.data.first&.id
      rescue Stripe::StripeError => e
        Rollbar.error(e, customer_id: customer_id, context: 'get_latest_payment_method')
        nil
      end
    end
  end
end
