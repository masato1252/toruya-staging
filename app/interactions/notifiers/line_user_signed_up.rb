module Notifiers
  class LineUserSignedUp < Base
    deliver_by :line

    def message
      I18n.t("user_bot.user_sign_up.line.successful_message")
    end
  end
end
