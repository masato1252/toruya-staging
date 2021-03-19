# frozen_string_literal: true

module Plans
  class Price < ActiveInteraction::Base
    BUSINESS_SIGNUP_FEE = { jpy: 8_800 }.freeze

    object :user
    object :plan
    boolean :with_shop_fee, default: false
    boolean :with_business_signup_fee, default: false

    def execute
      plan_cost =
        if plan.is_child?
          user.subscription_charges.completed.exists? ? plan.cost_with_currency.second : plan.cost_with_currency.first
        else
          plan.cost_with_currency
        end


      if plan.business_level? && with_business_signup_fee
        plan_cost = plan_cost + Money.new(BUSINESS_SIGNUP_FEE[Money.default_currency.id], Money.default_currency.id)
      end

      if with_shop_fee
        plan_cost = plan_cost + compose(Plans::Fee, user: user, plan: plan)
      end

      plan_cost
    end
  end
end
