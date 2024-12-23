# frozen_string_literal: true

module Subscriptions
  class ShopFeeCharge < ActiveInteraction::Base
    object :user
    object :shop
    string :authorize_token

    def execute
      compose(Payments::StoreStripeCustomer, user: user, authorize_token: authorize_token)
      charge = compose(Subscriptions::Charge,
                       user: user,
                       plan: Plan.premium_level.take,
                       charge_amount: Money.new(Plans::Fee::PER_SHOP_FEE[user.currency], user.currency),
                       charge_description: SubscriptionCharge::TYPES[:shop_fee],
                       manual: true)

      charge.details = {
        shop_ids: shop.id,
        type: SubscriptionCharge::TYPES[:shop_fee],
        user_name: user.name,
        user_email: user.email
      }
      charge.save!
      charge
    end
  end
end
