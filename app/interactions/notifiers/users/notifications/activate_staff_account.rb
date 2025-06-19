# frozen_string_literal: true

module Notifiers
  module Users
    module Notifications
      class ActivateStaffAccount < Base
        deliver_by_priority [:email, :sms]

        validate :receiver_should_be_staff_account

        def message
          I18n.t(
            "notifier.notifications.activate_staff_account.message",
            user_name: receiver.owner.name,
            url: Rails.application.routes.url_helpers.lines_user_bot_line_sign_up_url(staff_token: receiver.token, locale: receiver.owner.social_user&.locale)
          )
        end
      end
    end
  end
end
