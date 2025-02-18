# frozen_string_literal: true

require "translator"

module Notifiers
  module Customers
    module CustomMessages
      class EpisodeWatched < Base
        object :custom_message

        validate :receiver_should_be_customer
        validate :service_should_be_episode

        def message
          compose(::CustomMessages::ReceiverContent, custom_message: custom_message, receiver: receiver, variable_source: custom_message.service)
        end

        def deliverable
          receiver.online_service_customer_relations.where(online_service: online_service).exists?
        end

        def execute
          super

          custom_message.with_lock do
            custom_message.update(receiver_ids: custom_message.receiver_ids.push(receiver.id).map(&:to_s).uniq) if deliverable
          end
        end

        private

        def online_service
          @online_service ||= episode.online_service
        end

        def episode
          @episode ||= custom_message.service
        end

        def service_should_be_episode
          unless custom_message.service.is_a?(Episode)
            errors.add(:custom_message, :is_invalid_service)
          end
        end
      end
    end
  end
end
