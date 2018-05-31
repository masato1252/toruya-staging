# Fail: mail
# Success
#  charge current plan, set expire date
#  charge next plan cost(handle free plan), change to next plan, set expire date
module Subscriptions
  class RecurringCharge < ActiveInteraction::Base
    object :subscription

    def execute
      if subscription.next_plan
        if subscription.next_plan.cost.zero?
        else
        end
      else
      end
    end
  end
end
