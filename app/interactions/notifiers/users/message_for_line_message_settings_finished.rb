# frozen_string_literal: true

module Notifiers
  module Users
    class MessageForLineMessageSettingsFinished < Base
      deliver_by :line

      def message
        I18n.t("notifier.line_message_api_settings_finished.message")
      end
    end
  end
end
