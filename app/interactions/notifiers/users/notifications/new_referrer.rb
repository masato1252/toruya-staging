# frozen_string_literal: true

module Notifiers
  module Users
    module Notifications
      class NewReferrer < Base
        deliver_by_priority [:line, :sms, :email]

        def message
          I18n.t("notifier.notifications.new_referrer.message", user_name: receiver.name).strip
        end
      end
    end
  end
end
