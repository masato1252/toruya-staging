# frozen_string_literal: true

module Plans
  class Property < ActiveInteraction::Base
    object :user
    object :plan

    def execute
      plan_level = Plan.permission_level(plan.level)

      selectable =
        if user.child_plan_member? && plan.free_level?
          user.subscription_charges.completed.exists?
        else
          true
        end

      details = I18n.t("plans")[plan.level.to_sym].dup.merge!(
        customer_number: I18n.t("plans.#{plan.level}.customer_number", customer_limit:  Plan.max_customers_limit(plan.level, 0)),
      )

      if plan.level != "free"
        details.merge!(
          ranks: Plan.plans[plan.level]
          .map { |rank_context| rank_context.merge!(costFormat: rank_context[:cost].to_money(user.currency).format) }
        )
      end

      Hashie::Mash.new({
        level: plan_level,
        key: plan.level,
        selectable: selectable,
        name: plan.name,
        details: details
      })
    end
  end
end
