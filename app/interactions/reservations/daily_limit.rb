# frozen_string_literal: true

module Reservations
  class DailyLimit < ActiveInteraction::Base
    RESERVATION_DAILY_LIMIT = 10

    object :user

    def execute
      if !user.premium_member? && user.today_reservations_count >= RESERVATION_DAILY_LIMIT
        errors.add(:user, :exceed_reservations_daily_limit)
      end
    end
  end
end
