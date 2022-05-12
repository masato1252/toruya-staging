# frozen_string_literal: true

require "message_encryptor"

module Notifiers
  class LineSettingsFinished < Base
    deliver_by :line

    def message
      I18n.t("notifier.line_api_settings_finished.message")
    end
  end
end
