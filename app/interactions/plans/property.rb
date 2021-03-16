# frozen_string_literal: true

module Plans
  class Property < ActiveInteraction::Base
    object :user
    object :plan

    def execute
      cost = Plans::Price.run!(user: user, plan: plan)
      cost_with_shop_fee = Plans::Price.run!(user: user, plan: plan, with_shop_fee: true, with_business_signup_fee: true)
      plan_level = Plan.permission_level(plan.level)

      selectable =
        if user.child_plan_member? && plan.free_level?
          user.subscription_charges.completed.exists?
        else
          true
        end

      details = I18n.t("plans")[plan.level.to_sym].merge!(
        customer_number: I18n.t("plans.#{plan.level}.customer_number", customer_limit: Ability::CUSTOMER_LIMIT[plan.level]),
        sale_page_number: I18n.t("plans.#{plan.level}.sale_page_number", sale_page_limit: Ability::SALE_PAGE_LIMIT[plan.level])
      )

      Hashie::Mash.new({
        level: plan_level,
        key: plan.level,
        selectable: selectable,
        cost: cost.fractional,
        costWithFee: cost_with_shop_fee.fractional,
        costFormat: cost.format,
        name: plan.name,
        details: details
      })
    end
  end
end
