# frozen_string_literal: true

module Customers
  class StoreStripeCustomer < ActiveInteraction::Base
    object :customer
    string :authorize_token
    string :payment_intent_id, default: nil
    string :setup_intent_id, default: nil

    def execute
      stripe_customer_id = customer.stripe_customer_id

      # Handle 3DS completion - retrieve the SetupIntent and get the PaymentMethod
      if setup_intent_id.present?
        setup_intent = Stripe::SetupIntent.retrieve(
          setup_intent_id,
          stripe_account: customer.user.stripe_provider.uid
        )

        case setup_intent.status
        when 'succeeded'
          payment_method_id = setup_intent.payment_method

          # Setup completed successfully, now set as default payment method
          if stripe_customer_id.present?
            Stripe::Customer.update(
              stripe_customer_id,
              {
                invoice_settings: {
                  default_payment_method: payment_method_id
                }
              },
              stripe_account: customer.user.stripe_provider.uid
            )
          end

          return payment_method_id
        when 'requires_action', 'requires_payment_method', 'requires_confirmation'
          errors.add(:customer, :requires_action, client_secret: setup_intent.client_secret)
          return nil
        else
          errors.add(:customer, :failed)
          return nil
        end
      end

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
              errors.add(:customer, :requires_action, client_secret: payment_intent.client_secret)
              return nil
            else
              errors.add(:customer, :failed)
              return nil
            end
          else
            # Check if authorize_token is already a PaymentMethod ID
            if authorize_token.start_with?('pm_')
              # Already a PaymentMethod ID, use it directly
              payment_method_id = authorize_token
            else
              # It's a card token, need to create PaymentMethod
              payment_method = Stripe::PaymentMethod.create(
                {
                  type: 'card',
                  card: { token: authorize_token }
                },
                stripe_account: customer.user.stripe_provider.uid
              )
              payment_method_id = payment_method.id
            end

            # Create SetupIntent to verify PaymentMethod (supports 3DS)
            setup_intent = Stripe::SetupIntent.create(
              {
                customer: stripe_customer_id,
                payment_method: payment_method_id,
                confirm: true,  # Attempt to confirm immediately
                usage: 'off_session',  # Set for future off-session use
                payment_method_types: ['card']
              },
              stripe_account: customer.user.stripe_provider.uid
            )

            case setup_intent.status
            when 'succeeded'
              # Verification successful, set as default payment method
              Stripe::Customer.update(
                stripe_customer_id,
                {
                  invoice_settings: {
                    default_payment_method: payment_method_id
                  }
                },
                stripe_account: customer.user.stripe_provider.uid
              )

              return payment_method_id
            when 'requires_action', 'requires_payment_method', 'requires_confirmation'
              # Requires 3DS verification, return client_secret for frontend processing
              errors.add(:customer, :requires_action, client_secret: setup_intent.client_secret, setup_intent_id: setup_intent.id)
              return nil
            else
              errors.add(:customer, :failed)
              return nil
            end
          end
        rescue => e
          Rollbar.error(e)
          errors.add(:authorize_token, :something_wrong)
          return nil
        end
      end

      # For new customers, create customer and setup payment method
      begin
        # Check if authorize_token is already a PaymentMethod ID
        if authorize_token.start_with?('pm_')
          # Already a PaymentMethod ID, use it directly
          payment_method_id = authorize_token
        else
          # It's a card token, need to create PaymentMethod
          payment_method = Stripe::PaymentMethod.create(
            {
              type: 'card',
              card: { token: authorize_token }
            },
            stripe_account: customer.user.stripe_provider.uid
          )
          payment_method_id = payment_method.id
        end

        # Create new customer
        stripe_customer = Stripe::Customer.create(
          {
            email: customer.email,
            phone: customer.phone_number
          },
          stripe_account: customer.user.stripe_provider.uid
        )

        customer.stripe_customer_id = stripe_customer.id
        customer.save

        # Create SetupIntent to verify PaymentMethod (supports 3DS)
        setup_intent = Stripe::SetupIntent.create(
          {
            customer: stripe_customer.id,
            payment_method: payment_method_id,
            confirm: true,  # Attempt to confirm immediately
            usage: 'off_session',  # Set for future off-session use
            payment_method_types: ['card']
          },
          stripe_account: customer.user.stripe_provider.uid
        )

        case setup_intent.status
        when 'succeeded'
          # Verification successful, set as default payment method
          Stripe::Customer.update(
            stripe_customer.id,
            {
              invoice_settings: {
                default_payment_method: payment_method_id
              }
            },
            stripe_account: customer.user.stripe_provider.uid
          )

          payment_method_id
        when 'requires_action', 'requires_payment_method', 'requires_confirmation'
          # Requires 3DS verification, return client_secret for frontend processing
          errors.add(:customer, :requires_action, client_secret: setup_intent.client_secret, setup_intent_id: setup_intent.id)
          nil
        else
          errors.add(:customer, :failed)
          nil
        end
      rescue => e
        Rollbar.error(e)
        errors.add(:authorize_token, :something_wrong)
        nil
      end
    end
  end
end
