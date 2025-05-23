# frozen_string_literal: true

module Payments
  class StoreStripeCustomer < ActiveInteraction::Base
    object :user
    string :authorize_token

    def execute
      begin
        stripe_customer = Stripe::Customer.create(
          email: user.email,
          phone: user.phone_number,
          payment_method: authorize_token,
          invoice_settings: {
            default_payment_method: authorize_token
          }
        )

        user.subscription.update!(
          stripe_customer_id: stripe_customer.id
        )
      rescue Stripe::CardError => error
        errors.add(:user, :auth_failed)
        Rollbar.error(error, toruya_user: user.id, stripe_charge: error.json_body[:error])
      rescue Stripe::StripeError => error
        if !error.message.include?("already been attached")
          errors.add(:user, :processor_failed)
          Rollbar.error(error, toruya_user: user.id, stripe_charge: error.json_body[:error])
        end
      end
    end
  end
end
