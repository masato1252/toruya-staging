# frozen_string_literal: true

module Plans
  class Price < ActiveInteraction::Base
    object :user
    object :plan
    integer :rank, default: nil

    def execute
      plan_cost = plan.cost_with_currency(rank || charging_rank)

      if !plan.free_level? && !plan_cost.positive?
        errors.add(:plan, :invalid_price)
      end

      plan_cost
    end

    private

    def charging_rank
      current_rank = Plan.rank(plan.level, user.customers.size)
      paying_rank = user.subscription.rank

      if user.subscription.plan == plan && current_rank < paying_rank
        current_rank = paying_rank
      end

      current_rank
    end
  end
end
