module Notifiers
  class ActivateStaffAccount < Base
    deliver_by_priority [:sms, :email], mailer: NotificationMailer, mailer_method: :activate_staff_account

    def message
      # HARUKO_TODO: Tweak required
      I18n.t("notifier.activate_staff_account.message", url: url_helpers.user_from_callbacks_staff_accounts_url(token: receiver.token))
    end
  end
end
