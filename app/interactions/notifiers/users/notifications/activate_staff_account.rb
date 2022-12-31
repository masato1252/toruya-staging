# frozen_string_literal: true

module Notifiers
  module Users
    module Notifications
      class ActivateStaffAccount < Base
        deliver_by :sms

        validate :receiver_should_be_staff_account

        def message
          I18n.t("notifier.notifications.activate_staff_account.message", url: Rails.application.routes.url_helpers.lines_user_bot_line_sign_up_url(staff_token: receiver.token))
        end
      end
    end
  end
end
