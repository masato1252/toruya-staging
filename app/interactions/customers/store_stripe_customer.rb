# frozen_string_literal: true

module Customers
  class StoreStripeCustomer < ActiveInteraction::Base
    object :customer
    string :authorize_token
    string :payment_intent_id, default: nil

    def execute
      stripe_customer_id = customer.stripe_customer_id

      if stripe_customer_id
        # update customer a new card
        begin
          if payment_intent_id
            payment_intent = Stripe::PaymentIntent.retrieve(
              payment_intent_id,
              stripe_account: customer.user.stripe_provider.uid
            )

            case payment_intent.status
            when 'succeeded'
              # Payment method is already attached to the customer
              return stripe_customer_id
            when 'requires_action', 'requires_payment_method', 'requires_confirmation'
              errors.add(:payment_intent, :requires_action)
              errors.add(:client_secret, payment_intent.client_secret)
              return nil
            else
              errors.add(:payment_intent, :failed)
              return nil
            end
          else
            # First attach the payment method to the customer
            Stripe::PaymentMethod.attach(
              authorize_token,
              { customer: stripe_customer_id },
              stripe_account: customer.user.stripe_provider.uid
            )

            # Then set it as the default payment method
            Stripe::Customer.update(
              stripe_customer_id,
              {
                invoice_settings: {
                  default_payment_method: authorize_token
                }
              },
              stripe_account: customer.user.stripe_provider.uid
            )
            return stripe_customer_id
          end
        rescue => e
          Rollbar.error(e)
          errors.add(:authorize_token, :something_wrong)
          return nil
        end
      end

      # For new customers, create with the payment method
      begin
        stripe_customer = Stripe::Customer.create(
          {
            payment_method: authorize_token,
            invoice_settings: {
              default_payment_method: authorize_token
            }
          },
          stripe_account: customer.user.stripe_provider.uid
        )
        customer.stripe_customer_id = stripe_customer.id
        customer.save
        stripe_customer.id
      rescue => e
        Rollbar.error(e)
        errors.add(:authorize_token, :something_wrong)
        nil
      end
    end
  end
end
