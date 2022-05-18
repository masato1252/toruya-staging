# frozen_string_literal: true

module Notifiers
  module Users
    module LineSettings
      class VerifyFailedMessage < Base
        deliver_by :line

        def message
          I18n.t("notifier.line_verification_failed.message")
        end
      end
    end
  end
end
