# frozen_string_literal: true

require "translator"

module Notifiers
  module OnlineServices
    class Purchased < Base
      deliver_by :line

      object :sale_page

      def message
        online_service = sale_page.product
        template = CustomMessage.template_of(online_service, CustomMessage::ONLINE_SERVICE_PURCHASED)

        Translator.perform(template, { customer_name: customer.name, service_title: online_service.name })
      end
    end
  end
end
