module Referrals
  class Build < ActiveInteraction::Base
    object :referee, class: User
    object :referrer, class: User

    validate :validate_referrer
    validate :validate_referee
    validate :validate_the_same_user

    def execute
      referrer.build_reference(referee: referee)
    end

    private

    def validate_referrer
      if referrer.persisted?
        errors.add(:referrer, :is_existing)
      end
    end

    def validate_referee
      unless referee.business_member?
        errors.add(:referee, :invalid_plan)
      end
    end

    def validate_the_same_user
      if referee == referrer
        errors.add(:referrer, :invalid_referrer)
      end
    end
  end
end
