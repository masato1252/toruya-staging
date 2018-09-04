module Subscriptions
  class ShopFeeCharge < ActiveInteraction::Base
    object :user
    string :authorize_token

    def execute
      compose(Payments::StoreStripeCustomer, user: user, authorize_token: authorize_token)
      charge = compose(Subscriptions::Charge,
                       user: user,
                       plan: Plan.premium_level.take,
                       charge_amount: Money.new(Plans::Fee::PER_SHOP_FEE, Money.default_currency.id),
                       charge_description: "Shop fee",
                       manual: true)

      # change to shop fee mail
      # SubscriptionMailer.charge_successfully(subscription).deliver_now
    end
  end
end
