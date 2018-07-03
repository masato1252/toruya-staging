module Payments
  class StoreStripeCustomer < ActiveInteraction::Base
    object :user
    string :authorize_token

    def execute
      stripe_customer_id = user.subscription.stripe_customer_id

      if stripe_customer_id
        # update customer a new card
        stripe_customer = Stripe::Customer.retrieve(stripe_customer_id)
        stripe_customer.source = authorize_token
        stripe_customer.save
        stripe_customer_id
      else
        stripe_customer = Stripe::Customer.create(source: authorize_token, email: user.email)
        user.subscription.stripe_customer_id = stripe_customer.id
        user.subscription.save
        stripe_customer.id
      end
    end
  end
end
