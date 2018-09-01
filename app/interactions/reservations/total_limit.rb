module Reservations
  class TotalLimit < ActiveInteraction::Base
    TOTAL_RESERVATIONS_LIMITS = {
      Plan::FREE_LEVEL  => 1_200,
      Plan::TRIAL_LEVEL => 1_200,
      Plan::BASIC_LEVEL => 3_600
    }.freeze

    object :user

    def execute
      if user.member_level != Plan::PREMIUM_LEVEL && Reservation.total_in_user(user) >= TOTAL_RESERVATIONS_LIMITS[user.member_level]
        errors.add(:user, :exceed_reservations_total_limit)
      end
    end
  end
end
