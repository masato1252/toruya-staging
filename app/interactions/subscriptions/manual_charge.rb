module Subscriptions
  class ManualCharge < ActiveInteraction::Base
    object :subscription
    object :plan
    string :authorize_token

    def execute
      user = subscription.user

      subscription.transaction do
        stripe_customer_id = compose(Payments::StoreStripeCustomer, user: user, authorize_token: authorize_token)
        compose(Subscriptions::Charge, user: user, plan: plan, stripe_customer_id: stripe_customer_id, manual: true)

        subscription.plan = plan
        subscription.next_plan = nil
        subscription.set_recurring_day
        subscription.set_expire_date
        subscription.save!
      end
    end
  end
end
