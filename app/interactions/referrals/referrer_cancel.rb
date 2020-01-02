module Referrals
  class ReferrerCancel < ActiveInteraction::Base
    object :referral

    validate :validate_referral

    def execute
      referral.referrer_canceled!
    end

    private

    def validate_referral
      if !referral.pending? && !referral.active?
        errors.add(:referral, :invalid_referral_state)
      end
    end
  end
end
