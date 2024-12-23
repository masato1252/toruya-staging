# frozen_string_literal: true

module Plans
  class Fee < ActiveInteraction::Base
    SHOP_NUMBER_CHARGE_THRESHOLD = 2
    PER_SHOP_FEE = { "JPY" => 500, "TWD" => 100 }.freeze

    object :user
    object :plan

    def execute
      plan.premium_level? ? Money.new(
        [user.shops.count - SHOP_NUMBER_CHARGE_THRESHOLD, 0].max * PER_SHOP_FEE[user.currency], user.currency
      ) : Money.zero(user.currency)
    end
  end
end
