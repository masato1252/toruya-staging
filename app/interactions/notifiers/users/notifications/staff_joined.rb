# frozen_string_literal: true

module Notifiers
  module Users
    module Notifications
      class StaffJoined < Base
        deliver_by :line

        def message
          I18n.t("notifier.notifications.staff_joined.message", staff_name: receiver.user.name)
        end
      end
    end
  end
end
