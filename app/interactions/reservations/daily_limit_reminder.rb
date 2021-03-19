# frozen_string_literal: true

module Reservations
  class DailyLimitReminder < ActiveInteraction::Base
    object :user
    object :reservation

    def execute
      if Reservations::DailyLimit.run(user: user).invalid?
        if created_by_admin?
          Notifiers::Reminders::DailyReservationsLimitByAdminReminder.perform_later(
            receiver: user,
            user: user
          )
        else
          Notifiers::Reminders::DailyReservationsLimitByStaffReminder.perform_later(
            receiver: user,
            user: user,
            shop: reservation.shop
          )
        end
      end
    end

    private

    def created_by_admin?
      reservation.by_staff&.user == user
    end
  end
end
