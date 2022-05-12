# frozen_string_literal: true

module Notifiers
  module Users
    class LineVerificationMessageFailed < Base
      deliver_by :line

      def message
        I18n.t("notifier.line_verification_failed.message")
      end
    end
  end
end
