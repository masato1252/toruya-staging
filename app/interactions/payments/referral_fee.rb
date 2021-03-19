# frozen_string_literal: true

module Payments
  class ReferralFee < ActiveInteraction::Base
    BONUS_FEE_RATIO = 0.1

    object :referral
    object :charge, class: SubscriptionCharge

    validate :validate_referee
    validate :validate_charge
    validate :validate_referral

    def execute
      payment = Payment.create(
        receiver: referee,
        referrer: referrer,
        amount: charge.amount * BONUS_FEE_RATIO,
        charge: charge,
        details: {
          type: Payment::TYPES[:referral_connect]
        }
      )

      if payment.new_record?
        errors.merge!(payment.errors)
      end

      payment
    end

    private

    def validate_referee
      unless referee.business_member?
        errors.add(:referral, :invalid_referee_plan)
      end
    end

    def validate_charge
      unless charge.completed?
        errors.add(:charge, :invalid_state)
      end
    end

    def validate_referral
      if !referral.pending? && !referral.active?
        errors.add(:referral, :invalid_referral_state)
      end
    end

    def referee
      @referee ||= referral.referee
    end

    def referrer
      @referrer ||= referral.referrer
    end
  end
end
