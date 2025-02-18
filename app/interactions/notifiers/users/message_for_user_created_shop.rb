# frozen_string_literal: true

module Notifiers
  module Users
    class MessageForUserCreatedShop < Base
      deliver_by_priority [:line, :sms, :email]

      def message
        I18n.t("notifier.created_shop.message", trial_end_date: receiver.user.subscription.trial_expired_date.to_s)
      end
    end
  end
end
