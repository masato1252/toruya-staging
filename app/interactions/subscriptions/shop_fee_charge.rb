# frozen_string_literal: true

module Subscriptions
  class ShopFeeCharge < ActiveInteraction::Base
    object :user
    string :authorize_token, default: nil
    string :payment_intent_id, default: nil

    def execute
      proration = compose(ShopFeeProration, user: user)
      charge_amount = proration[:amount]
      plan = user.subscription.plan

      if authorize_token.present? && payment_intent_id.blank?
        compose(Payments::StoreStripeCustomer,
                user: user,
                authorize_token: authorize_token,
                payment_intent_id: payment_intent_id)
      end

      charge = compose(Subscriptions::Charge,
                       user: user,
                       plan: plan,
                       charge_amount: charge_amount,
                       charge_description: SubscriptionCharge::TYPES[:shop_fee],
                       manual: true,
                       payment_intent_id: payment_intent_id,
                       payment_method_id: authorize_token)

      return charge unless charge.completed?

      charge.details = {
        type: SubscriptionCharge::TYPES[:shop_fee],
        user_name: user.name,
        user_email: user.email,
        monthly_fee: proration[:monthly_fee].fractional,
        monthly_fee_format: proration[:monthly_fee].format,
        period_start: proration[:period_start].to_s,
        period_end: proration[:period_end].to_s,
        prorated: true
      }
      charge.save!
      charge
    end
  end
end
