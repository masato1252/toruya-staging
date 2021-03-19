# frozen_string_literal: true

module Plans
  class Fee < ActiveInteraction::Base
    SHOP_NUMBER_CHARGE_THRESHOLD = 2
    PER_SHOP_FEE = 500

    object :user
    object :plan

    def execute
      plan.premium_level? ? Money.new([user.shops.count - SHOP_NUMBER_CHARGE_THRESHOLD, 0].max * PER_SHOP_FEE, Money.default_currency.id) : Money.zero
    end
  end
end
