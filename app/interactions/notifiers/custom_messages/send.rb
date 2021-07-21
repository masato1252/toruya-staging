# frozen_string_literal: true

require "translator"

module Notifiers
  module CustomMessages
    class Send < Base
      deliver_by :line

      object :custom_message

      validate :receiver_should_be_customer

      def message
        Translator.perform(custom_message.content, { customer_name: receiver.display_last_name, service_title: custom_message.service.name })
      end

      def deliverable
        custom_message.receiver_ids.exclude?(receiver.id.to_s)
      end

      def execute
        super

        return unless deliverable
        custom_message.with_lock do
          custom_message.update(receiver_ids: custom_message.receiver_ids.push(receiver.id).uniq)
        end

        ::CustomMessages::Next.run(
          custom_message: custom_message,
          receiver: receiver
        )
      end
    end
  end
end
