# frozen_string_literal: true

require "translator"

module Notifiers
  module Customers
    module OnlineServices
      class Purchased < Base
        object :online_service

        validate :receiver_should_be_customer

        def message
          template = ::CustomMessages::Customers::Template.run!(product: online_service, scenario: ::CustomMessages::Customers::Template::ONLINE_SERVICE_PURCHASED)

          Translator.perform(template, online_service.message_template_variables(receiver))
        end

        def execute
          # XXX: Send message
          super

          if custom_message = CustomMessage.scenario_of(online_service, ::CustomMessages::Customers::Template::ONLINE_SERVICE_PURCHASED).right_away.first
            custom_message.with_lock do
              custom_message.update(receiver_ids: custom_message.receiver_ids.push(receiver.id).map(&:to_s).uniq)
            end
          end

          ::CustomMessages::Customers::Next.run(
            product: online_service,
            scenario: ::CustomMessages::Customers::Template::ONLINE_SERVICE_PURCHASED,
            receiver: receiver
          )
        end
      end
    end
  end
end
