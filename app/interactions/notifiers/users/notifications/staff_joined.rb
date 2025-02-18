# frozen_string_literal: true

module Notifiers
  module Users
    module Notifications
      class StaffJoined < Base
        deliver_by_priority [:line, :sms, :email]
        string :staff_name

        def message
          I18n.t("notifier.notifications.staff_joined.message", staff_name: staff_name)
        end
      end
    end
  end
end
