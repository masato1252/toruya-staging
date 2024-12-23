# frozen_string_literal: true

module Payments
  class ReferralDisconnectFee < ActiveInteraction::Base
    FEE = { "JPY" => 5_500, "TWD" => 200 }.freeze

    object :referral
    object :charge, class: SubscriptionCharge

    def execute
      payment = Payment.create(
        receiver: referral.referee,
        referrer: referral.referrer,
        charge: charge,
        amount: Money.new(FEE[user_currency], user_currency),
        details: {
          type: Payment::TYPES[:referral_disconnect]
        }
      )

      if payment.new_record?
        errors.merge!(payment.errors)
      end

      payment
    end

    private

    def user_currency
      charge.user.currency
    end
  end
end
