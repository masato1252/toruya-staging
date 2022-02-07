# frozen_string_literal: true

module Notifiers
  class MessageForUserCreatedShop < Base
    deliver_by :line

    def message
      I18n.t("notifier.created_shop.message")
    end
  end
end
