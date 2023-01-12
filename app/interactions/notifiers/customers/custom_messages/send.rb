# frozen_string_literal: true

require "translator"

module Notifiers
  module Customers
    module CustomMessages
      class Send < Base
        deliver_by :line

        object :custom_message

        validate :receiver_should_be_customer
        validate :service_should_be_online_service

        def message
          compose(::CustomMessages::ReceiverContent, custom_message: custom_message, receiver: receiver, variable_source: custom_message.service)
        end

        def deliverable
          expected_schedule_time &&
            custom_message.receiver_ids.exclude?(receiver.id.to_s) &&
            receiver.online_service_customer_relations.where(online_service: custom_message.service).exists?
        end

        def execute
          super

          custom_message.with_lock do
            custom_message.update(receiver_ids: custom_message.receiver_ids.push(receiver.id).map(&:to_s).uniq) if deliverable
          end

          ::CustomMessages::Customers::Next.run(
            custom_message: custom_message,
            receiver: receiver
          )
        end

        private

        def expected_schedule_time
          if schedule_at && custom_message.after_days
            expected_schedule_at = custom_message.service.start_at_for_customer(receiver).advance(days: custom_message.after_days).change(hour: 9)
            # app/interactions/custom_messages/customers/next.rb
            # schedule_at = message_product.start_at_for_customer(receiver).advance(days: message.after_days).change(hour: 9, min: rand(5), sec: rand(59))
            # We used rand number to tweak schedule time in above file to avoid duplicate message,
            # but that might also cause our schedule time validation was incorrect so change it back here - change(hour: 9)
            return expected_schedule_at.to_s(:iso8601) == schedule_at.change(hour: 9).to_s(:iso8601)
          end

          true # real time
        end

        def service_should_be_online_service
          unless custom_message.service.is_a?(OnlineService)
            errors.add(:custom_message, :is_invalid_service)
          end
        end
      end
    end
  end
end
