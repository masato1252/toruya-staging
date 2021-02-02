# frozen_string_literal: true

module Payments
  class ReferralDisconnectFee < ActiveInteraction::Base
    FEE = { jpy: 5_500 }.freeze

    object :referral
    object :charge, class: SubscriptionCharge

    def execute
      payment = Payment.create(
        receiver: referral.referee,
        referrer: referral.referrer,
        charge: charge,
        amount: Money.new(FEE[Money.default_currency.id], Money.default_currency.id),
        details: {
          type: Payment::TYPES[:referral_disconnect]
        }
      )

      if payment.new_record?
        errors.merge!(payment.errors)
      end

      payment
    end
  end
end
