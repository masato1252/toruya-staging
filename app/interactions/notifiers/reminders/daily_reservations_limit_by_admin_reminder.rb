module Notifiers
  module Reminders
    class DailyReservationsLimitByAdminReminder < Base
      deliver_by_priority [:line, :sms, :email], mailer: ReminderMailer, mailer_method: :daily_reservations_limit_by_admin_reminder

      def message
        I18n.t(
          "notifier.reminders.daily_reservations_limit_by_admin_reminder.message",
          user_name: user.name,
          plan_name: user.member_plan_name,
          reservation_daily_limit: Reservations::DailyLimit::RESERVATION_DAILY_LIMIT,
          total_reservations_limit: Reservations::TotalLimit::TOTAL_RESERVATIONS_LIMITS[user.permission_level],
          total_reservations_count: user.total_reservations_count
        )
      end
    end
  end
end
