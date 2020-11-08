module Notifiers
  module Reminders
    class TotalReservationsLimitByStaffReminder < Base
      deliver_by_priority [:line, :sms, :email]

      object :shop

      def message
        I18n.t(
          "notifier.reminders.total_reservations_limit_by_staff_reminder.message",
          user_name: user.name,
          shop_name: shop.name,
          plan_name: user.member_plan_name,
          reservation_daily_limit: Reservations::DailyLimit::RESERVATION_DAILY_LIMIT,
          today_reservations_count: user.today_reservations_count,
          total_reservations_limit: Reservations::TotalLimit::TOTAL_RESERVATIONS_LIMITS[user.permission_level],
          total_reservations_count: user.total_reservations_count
        )
      end

      def send_email
        ReminderMailer.total_reservations_limit_by_staff_reminder(user, shop).deliver_now
      end
    end
  end
end
