# frozen_string_literal: true

module Notifiers
  module Users
    class MessageForUserCreatedShop < Base
      deliver_by :line

      def message
        I18n.t("notifier.created_shop.message")
      end
    end
  end
end
