# frozen_string_literal: true

module Notifiers
  module Users
    module Notifications
      class InviteConsultantClient < Base
        deliver_by :sms

        validate :receiver_should_be_consultant_account

        def message
          I18n.t(
            "notifier.notifications.invite_consultant_client.message",
            consultant_name: receiver.consultant_user.name,
            url: Rails.application.routes.url_helpers.lines_user_bot_line_sign_up_url(consultant_token: receiver.token, locale: receiver.consultant_user.social_user.locale)
          )
        end
      end
    end
  end
end
