# frozen_string_literal: true

module Subscriptions
  class ResidualValue < ActiveInteraction::Base
    object :user

    def execute
      if user.subscription.in_paid_plan && (last_charge = user.subscription_charges.last_plan_charged)
        last_charge.amount * Rational(last_charge.expired_date - Subscription.today, last_charge.expired_date - last_charge.charge_date)
      else
        Money.zero(user.currency)
      end
    end
  end
end
