# frozen_string_literal: true

require "translator"

module Notifiers
  module OnlineServices
    class Purchased < Base
      deliver_by :line

      object :sale_page

      validate :receiver_should_be_customer

      def message
        online_service = sale_page.product
        template = CustomMessage.template_of(online_service, CustomMessage::ONLINE_SERVICE_PURCHASED)

        Translator.perform(template, { customer_name: receiver.display_last_name, service_title: online_service.name })
      end

      def execute
        # XXX: Send message
        super

        ::CustomMessages::Next.run(
          product: sale_page.product,
          scenario: CustomMessage::ONLINE_SERVICE_PURCHASED,
          receiver: receiver
        )
      end
    end
  end
end
