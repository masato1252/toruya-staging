# frozen_string_literal: true

module Notifiers
  module Users
    module LineSettings
      class FinishedMessage < Base
        deliver_by_priority [:line, :sms, :email]

        def message
          I18n.t("notifier.line_api_settings_finished.message")
        end
      end
    end
  end
end