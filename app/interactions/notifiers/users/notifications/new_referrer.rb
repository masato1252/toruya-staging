# frozen_string_literal: true

module Notifiers
  module Users
    module Notifications
      class NewReferrer < Base
        deliver_by_priority [:line, :sms, :email], mailer: NotificationMailer, mailer_method: :new_referrer

        def message
          I18n.t("notifier.notifications.new_referrer.message", user_name: receiver.name)
        end
      end
    end
  end
end
