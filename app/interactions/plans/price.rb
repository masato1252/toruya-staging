# frozen_string_literal: true

module Plans
  class Price < ActiveInteraction::Base
    object :user
    object :plan
    integer :rank, default: nil

    def execute
      plan_cost = plan.cost_with_currency(charging_rank)

      if !plan.free_level? && !plan_cost.positive?
        errors.add(:plan, :invalid_price)
      end

      [plan_cost, charging_rank]
    end

    private

    def charging_rank
      return @charging_rank if defined?(@charging_rank)

      @charging_rank = Plan.rank(plan.level, user.customers.size)

      # XXX: We upgrade users rank automatically, but won't downgrade automatically for them,
      # because our goal is grow up our users' business, there is no reason to let users to decrease their customers
      if user.subscription.plan == plan
        @charging_rank = [@charging_rank, user.subscription.rank, rank].compact.max
      end

      @charging_rank
    end
  end
end
