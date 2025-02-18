# frozen_string_literal: true

require "message_encryptor"

module Notifiers
  module Users
    module LineSettings
      class VerifiedMessage < Base
        deliver_by_priority [:line, :sms, :email]

        def message
          I18n.t("notifier.line_api_settings_verified.message")
        end
      end
    end
  end
end
