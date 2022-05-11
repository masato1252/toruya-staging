# frozen_string_literal: true

require "message_encryptor"

module Notifiers
  class LineSettingsFinished < Base
    deliver_by :line

    def message
      I18n.t(
        "notifier.line_api_settings_finished.message",
        verification_url: Rails.application.routes.url_helpers.lines_verification_url(MessageEncryptor.encrypt(receiver.social_service_user_id))
      )
    end
  end
end
