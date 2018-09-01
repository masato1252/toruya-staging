module Reservations
  class DailyLimitReminder < ActiveInteraction::Base
    object :user
    object :reservation

    def execute
      if Reservations::DailyLimit.run(user: user).invalid?
        if created_by_admin?
          ReminderMailer.daily_reservations_limit_by_admin_reminder(user).deliver_later
        else
          ReminderMailer.daily_reservations_limit_by_staff_reminder(user, reservation).deliver_later
        end
      end
    end

    private

    def created_by_admin?
      reservation.by_staff.user == user
    end
  end
end
