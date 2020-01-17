module Reservations
  class TotalLimit < ActiveInteraction::Base
    TOTAL_RESERVATIONS_LIMITS = {
      Plan::FREE_LEVEL  => 1_200,
      Plan::TRIAL_LEVEL => 1_200,
      Plan::BASIC_LEVEL => 3_600
    }.freeze

    object :user

    def execute
      if !user.premium_member? && user.total_reservations_count >= TOTAL_RESERVATIONS_LIMITS[user.permission_level]
        errors.add(:user, :exceed_reservations_total_limit)
      end
    end
  end
end
