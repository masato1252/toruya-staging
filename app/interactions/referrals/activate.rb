# frozen_string_literal: true

module Referrals
  class Activate < ActiveInteraction::Base
    object :referral

    validate :validate_referral

    def execute
      referral.active!
    end

    private

    def validate_referral
      if referral.referrer_canceled?
        errors.add(:referral, :invalid_referral_state)
      end
    end
  end
end
