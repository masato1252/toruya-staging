# frozen_string_literal: true

module Notifiers
  module Users
    module LineSettings
      class LineChannelSecretIncorrectMessage < Base
        deliver_by_priority [:line, :sms, :email]

        def message
          I18n.t("line_verification.channel_secret_incorrect_message")
        end
      end
    end
  end
end
