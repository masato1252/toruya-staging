# frozen_string_literal: true

module Plans
  class Fee < ActiveInteraction::Base
    SHOP_NUMBER_CHARGE_THRESHOLD = 1
    PER_SHOP_FEE = { "JPY" => 550, "TWD" => 110 }.freeze

    object :user
    object :plan

    def execute
      return Money.zero(user.currency) unless chargeable?

      extra_shops = [user.shops.count - SHOP_NUMBER_CHARGE_THRESHOLD, 0].max
      Money.new(extra_shops * PER_SHOP_FEE[user.currency], user.currency)
    end

    def self.chargeable_for?(user, plan)
      user.subscription&.in_paid_plan? && !plan.enterprise_level?
    end

    private

    def chargeable?
      self.class.chargeable_for?(user, plan)
    end
  end
end
