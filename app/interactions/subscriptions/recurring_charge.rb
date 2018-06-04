# Fail: mail
# Success
#  charge current plan, set expire date
#  charge next plan cost(handle free plan), change to next plan, set expire date
module Subscriptions
  class RecurringCharge < ActiveInteraction::Base
    object :subscription

    def execute
      user = subscription.user

      charging_plan = subscription.next_plan || subscription.plan

      if charging_plan.cost.zero?
        subscription.update(plan: charging_plan, next_plan: nil)
      else
        subscription.transaction do
          compose(Subscriptions::Charge, user: user, plan: charging_plan, stripe_customer_id: subscription.stripe_customer_id, manual: false)

          subscription.plan = charging_plan
          subscription.next_plan = nil
          subscription.set_expire_date
          subscription.save!
        end
      end
    end
  end
end
