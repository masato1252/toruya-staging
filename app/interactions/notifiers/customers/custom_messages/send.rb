# frozen_string_literal: true

require "translator"

module Notifiers
  module Customers
    module CustomMessages
      class Send < Base
        deliver_by :line

        object :custom_message

        validate :receiver_should_be_customer

        def message
          compose(::CustomMessages::ReceiverContent, custom_message: custom_message, receiver: receiver)
        end

        def deliverable
          custom_message.receiver_ids.exclude?(receiver.id.to_s) &&
            custom_message.service.is_a?(OnlineService) && receiver.online_service_customer_relations.where(online_service: custom_message.service).exists?
        end

        def execute
          super

          custom_message.with_lock do
            custom_message.update(receiver_ids: custom_message.receiver_ids.push(receiver.id).map(&:to_s).uniq)
          end

          ::CustomMessages::Customers::Next.run(
            custom_message: custom_message,
            receiver: receiver
          )
        end
      end
    end
  end
end
