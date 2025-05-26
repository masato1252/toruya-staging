# frozen_string_literal: true

module Payments
  class StoreStripeCustomer < ActiveInteraction::Base
    object :user
    string :authorize_token
    string :setup_intent_id, default: nil
    string :payment_intent_id, default: nil

    def execute
      begin
        subscription = user.subscription

        if setup_intent_id.present?
          # Handle 3DS completion - retrieve the SetupIntent and get the PaymentMethod
          setup_intent = Stripe::SetupIntent.retrieve(setup_intent_id)

          case setup_intent.status
          when 'succeeded'
            payment_method_id = setup_intent.payment_method

            # Setup completed successfully, now set as default payment method
            if subscription.stripe_customer_id.present?
              Stripe::Customer.update(
                subscription.stripe_customer_id,
                {
                  invoice_settings: {
                    default_payment_method: payment_method_id
                  }
                }
              )
            end

            return payment_method_id
          when 'requires_action', 'requires_payment_method', 'requires_confirmation', "requires_source", "processing", "requires_source_action"
            errors.add(:customer, :requires_action, client_secret: setup_intent.client_secret, payment_intent_id: setup_intent.id)
            return nil
          else
            errors.add(:user, :failed)
            return nil
          end
        end

        if payment_intent_id.present?
          # Handle PaymentIntent completion after 3DS
          payment_intent = Stripe::PaymentIntent.retrieve(payment_intent_id)

          case payment_intent.status
          when 'succeeded'
            # Payment is succeeded, get the payment method and set as default
            if payment_intent.payment_method
              payment_method_id = payment_intent.payment_method

              # Ensure this payment method is set as customer's default
              if subscription.stripe_customer_id.present?
                Stripe::Customer.update(
                  subscription.stripe_customer_id,
                  {
                    invoice_settings: {
                      default_payment_method: payment_method_id
                    }
                  }
                )
              end

              return payment_method_id
            else
              errors.add(:user, :no_payment_method)
              return nil
            end
          when 'requires_action', 'requires_payment_method', 'requires_confirmation', "requires_source", "processing", "requires_source_action"
            errors.add(:user, :requires_action, client_secret: payment_intent.client_secret, payment_intent_id: payment_intent_id)
            return nil
          else
            errors.add(:user, :failed)
            return nil
          end
        end

        # 1. Check if authorize_token is already a PaymentMethod ID
        if authorize_token.start_with?('pm_')
          # Already a PaymentMethod ID, use it directly
          payment_method_id = authorize_token
        else
          # It's a card token, need to create PaymentMethod
          payment_method = Stripe::PaymentMethod.create(
            type: 'card',
            card: { token: authorize_token }
          )
          payment_method_id = payment_method.id
        end

        customer_id = if subscription.stripe_customer_id.present?
          subscription.stripe_customer_id
        else
          # Create new customer
          stripe_customer = Stripe::Customer.create(
            email: user.email,
            phone: user.phone_number
          )

          # Update subscription record
          subscription.update!(
            stripe_customer_id: stripe_customer.id
          )

          stripe_customer.id
        end

        # 2. Create SetupIntent to verify PaymentMethod (supports 3DS)
        setup_intent = Stripe::SetupIntent.create(
          customer: customer_id,
          payment_method: payment_method_id,
          confirm: true,  # Attempt to confirm immediately
          usage: 'off_session',  # Set for future off-session use
          payment_method_types: ['card']
        )

        case setup_intent.status
        when 'succeeded'
          # Verification successful, set as default payment method
          Stripe::Customer.update(
            customer_id,
            {
              invoice_settings: {
                default_payment_method: payment_method_id
              }
            }
          )

          payment_method_id
        when 'requires_action', 'requires_payment_method', 'requires_confirmation'
          # Requires 3DS verification, return client_secret for frontend processing
          errors.add(:user, :requires_action, client_secret: setup_intent.client_secret, setup_intent_id: setup_intent.id)
          nil
        else
          errors.add(:user, :failed)
          nil
        end

      rescue Stripe::CardError => error
        errors.add(:user, :auth_failed)
        Rollbar.error(error, toruya_user: user.id, stripe_charge: error.json_body&.dig(:error))
        nil
      rescue Stripe::StripeError => error
        if !error.message.include?("already been attached")
          errors.add(:user, :processor_failed)
          Rollbar.error(error, toruya_user: user.id, stripe_charge: error.json_body&.dig(:error))
        end
        nil
      end
    end
  end
end
