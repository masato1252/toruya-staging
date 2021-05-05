# frozen_string_literal: true

require "translator"

module Notifiers
  module OnlineServices
    class Purchased < Base
      deliver_by :line

      object :sale_page

      def message
        online_service = sale_page.product
        custom_message = CustomMessage.where(service: online_service, scenario: CustomMessage::ONLINE_SERVICE_PURCHASED).take

        if custom_message
          custom_message_content = Translator.perform(custom_message.content, { customer_name: customer.name, service_title: online_service.name })
        end

        custom_message_content || I18n.t("notifier.online_service.purchased.#{online_service.solution_type}.message", service_title: online_service.name)
      end
    end
  end
end
