# frozen_string_literal: true

module Notifiers
  module Users
    class ExtraNewLineAccount < Base
      deliver_by_priority [:line, :sms, :email]

      def message
        I18n.t("notifier.extra_new_line_account.successful_message")
      end
    end
  end
end
