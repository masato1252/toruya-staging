module Payments
  class StoreStripeCustomer < ActiveInteraction::Base
    object :user
    string :authorize_token

    def execute
      stripe_customer_id = user.subscription.stripe_customer_id

      if stripe_customer_id
        # update customer a new card
        begin
          Stripe::Customer.update(stripe_customer_id, {
            source: authorize_token,
          })
          return stripe_customer_id
        rescue => e
          Rollbar.error(e)
          errors.add(:base, e.message)
          return
          # raise e if e.code != "resource_missing"
        end
      end

      stripe_customer = Stripe::Customer.create(source: authorize_token, email: user.email)
      user.subscription.stripe_customer_id = stripe_customer.id
      user.subscription.save
      stripe_customer.id
    end
  end
end
