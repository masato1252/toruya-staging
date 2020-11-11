module Subscriptions
  class ResidualValue < ActiveInteraction::Base
    object :user

    def execute
      if user.subscription.in_paid_plan && user.subscription_charges.last_plan_charged
        user.subscription_charges.last_plan_charged.amount * Rational(user.subscription.expired_date - Subscription.today, Subscription::BASIC_PERIOD_DAYS)
      else
        Money.zero
      end
    end
  end
end
