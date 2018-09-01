module Reservations
  class DailyLimit < ActiveInteraction::Base
    RESERVATION_DAILY_LIMIT = 10

    object :user

    def execute
      if user.member_level != Plan::PREMIUM_LEVEL && Reservation.today_counts_in_user(user) >= RESERVATION_DAILY_LIMIT
        errors.add(:user, :exceed_reservations_daily_limit)
      end
    end
  end
end
