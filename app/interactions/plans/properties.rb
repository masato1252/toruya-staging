# frozen_string_literal: true

module Plans
  class Properties < ActiveInteraction::Base
    object :user

    def execute
      plan_levels =
        if user.business_member?
          [Plan::FREE_PLAN, Plan::BASIC_PLAN, Plan::BUSINESS_PLAN]
        elsif user.child_plan_member?
          [Plan::FREE_PLAN, *Plan::CHILD_PLANS]
        else
          Plan::REGULAR_PLANS
        end

      Hashie::Mash.new(
        Plan.where(level: plan_levels).each_with_object({}) do |plan, h|
          h[Plan.permission_level(plan.level)] = compose(Plans::Property, user: user, plan: plan)
        end
      )
    end
  end
end
