# frozen_string_literal: true

module Customers
  class StoreStripeCustomer < ActiveInteraction::Base
    object :customer
    string :authorize_token

    def execute
      stripe_customer_id = customer.stripe_customer_id

      if stripe_customer_id
        # update customer a new card
        begin
          Stripe::Customer.update(stripe_customer_id, {
            source: authorize_token,
          },
          stripe_account: customer.user.stripe_provider.uid
          )
          return stripe_customer_id
        rescue => e
          Rollbar.error(e)
          # errors.add(:authorize_token, :something_wrong)
          # return
          # raise e if e.code != "resource_missing"
        end
      end

      begin
        stripe_customer = Stripe::Customer.create(
          {
            source: authorize_token, email: customer.email, phone: customer.phone_number
          },
          stripe_account: customer.user.stripe_provider.uid
        )
        customer.stripe_customer_id = stripe_customer.id
        customer.save
        stripe_customer.id
      rescue Stripe::InvalidRequestError => e
        Rollbar.error(e)
        errors.add(:authorize_token, :something_wrong)
      end
    end
  end
end
