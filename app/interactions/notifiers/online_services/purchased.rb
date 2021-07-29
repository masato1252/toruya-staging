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

        if custom_message = CustomMessage.scenario_of(sale_page.product, CustomMessage::ONLINE_SERVICE_PURCHASED).right_away.first
          custom_message.with_lock do
            custom_message.update(receiver_ids: custom_message.receiver_ids.push(receiver.id).uniq)
          end
        end

        ::CustomMessages::Next.run(
          product: sale_page.product,
          scenario: CustomMessage::ONLINE_SERVICE_PURCHASED,
          receiver: receiver
        )
      end
    end
  end
end
