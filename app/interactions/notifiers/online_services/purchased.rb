# frozen_string_literal: true

require "translator"

module Notifiers
  module OnlineServices
    class Purchased < Base
      deliver_by :line

      object :sale_page

      def message
        custom_message = CustomMessage.where(service: sale_page.product, scenario: CustomMessage::ONLINE_SERVICE_PURCHASED).take

        if custom_message
          custom_message_content = Translator.perform(custom_message.content, { customer_name: customer.name, service_title: sale_page.product.name })
        end

        custom_message_content || I18n.t("notifier.online_service.purchased.message", service_title: sale_page.product.name)
      end
    end
  end
end
