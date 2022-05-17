# frozen_string_literal: true

module Notifiers
  module Users
    module LineSettings
      class LineLoginVerificationMessage < Base
        deliver_by :line

        def message
          I18n.t("line_verification.message_api_notification_message")
        end
      end
    end
  end
end
