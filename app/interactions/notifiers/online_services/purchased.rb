# frozen_string_literal: true

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

        if sale_page.free?
          custom_message_content || I18n.t("online_service_purchases.free_service.purchased_notification_message", service_title: sale_page.product.name)
        else
          custom_message_content || I18n.t("online_service_purchases.free_service.purchased_notification_message", service_title: sale_page.product.name)
        end
      end
    end
  end
end
