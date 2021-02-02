# frozen_string_literal: true

module Reservations
  class TotalLimitReminder < ActiveInteraction::Base
    object :user
    object :reservation

    def execute
      if Reservations::TotalLimit.run(user: user).invalid?
        if created_by_admin?
          Notifiers::Reminders::TotalReservationsLimitByAdminReminder.perform_later(
            receiver: user,
            user: user
          )
        else
          Notifiers::Reminders::TotalReservationsLimitByStaffReminder.perform_later(
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
