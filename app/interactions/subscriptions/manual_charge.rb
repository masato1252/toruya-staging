module Subscriptions
  class ManualCharge < ActiveInteraction::Base
    object :subscription
    object :plan
    string :authorize_token

    def execute
      user = subscription.user

      subscription.transaction do
        compose(Payments::StoreStripeCustomer, user: user, authorize_token: authorize_token)
        compose(Subscriptions::Charge, user: user, plan: plan, manual: true)

        subscription.plan = plan
        subscription.next_plan = nil
        subscription.set_recurring_day
        subscription.set_expire_date
        subscription.save!

        SubscriptionMailer.charge_successfully(subscription).deliver_now
      end
    end
  end
end
