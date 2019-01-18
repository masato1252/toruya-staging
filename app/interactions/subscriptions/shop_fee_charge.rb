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
                       charge_amount: Money.new(Plans::Fee::PER_SHOP_FEE, Money.default_currency.id),
                       charge_description: SubscriptionCharge::TYPES[:shop_fee],
                       manual: true)

      charge.details = {
        shop_ids: shop.id,
        type: SubscriptionCharge::TYPES[:shop_fee]
      }
      charge.save!

      SubscriptionMailer.charge_shop_fee(user.subscription, charge).deliver_later
      charge
    end
  end
end
