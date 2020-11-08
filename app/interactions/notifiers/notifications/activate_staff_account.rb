module Notifiers
  module Notifications
    class ActivateStaffAccount < Base
      deliver_by_priority [:line, :sms, :email], mailer: NotificationMailer, mailer_method: :activate_staff_account

      def message
        I18n.t("notifier.notifications.activate_staff_account.message")
      end
    end
  end
end
