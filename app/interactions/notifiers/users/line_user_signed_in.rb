# frozen_string_literal: true

module Notifiers
  module Users
    class LineUserSignedIn < Base
      deliver_by_priority [:line, :sms, :email]

      def message
        I18n.t("user_bot.guest.user_connect.line.successful_message")
      end
    end
  end
end
