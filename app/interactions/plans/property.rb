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

      Hashie::Mash.new({
        level: plan_level,
        key: plan.level,
        selectable: selectable,
        cost: cost.fractional,
        costWithFee: cost_with_shop_fee.fractional,
        costFormat: cost.format,
        name: plan.name,
        details: I18n.t("settings.plans")[plan.level.to_sym]
      })
    end
  end
end
