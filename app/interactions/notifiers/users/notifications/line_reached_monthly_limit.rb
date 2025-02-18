# frozen_string_literal: true

module Notifiers
  module Users
    module Notifications
      class LineReachedMonthlyLimit < Base
        deliver_by_priority [:line, :sms, :email]

        def message
          I18n.t("notifier.notifications.line_reached_monthly_limit.message")
        end
      end
    end
  end
end
