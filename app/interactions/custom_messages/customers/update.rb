# frozen_string_literal: true

module CustomMessages
  module Customers
    class Update < CustomMessages::Customers::Base
      object :message, class: CustomMessage
      string :content
      integer :after_days, default: nil
      integer :before_minutes, default: nil

      validate :validate_purchased_message

      def execute
        message.content = content
        message.after_days = after_days
        message.before_minutes = before_minutes

        if message.save
          if message.service.is_a?(OnlineService) && message.saved_change_to_after_days?
            notify_service_customers(message)
          end

          if message.service.is_a?(BookingPage) && message.saved_change_to_before_minutes?
            notify_reservation_customers(message)
          end
        end

        message
      end

      private

      def service
        @service ||= message.service
      end

      def validate_purchased_message
        if after_days.nil? && service.is_a?(OnlineService) && CustomMessage.scenario_of(message.service, message.scenario).right_away.where.not(id: message.id).exists?
          errors.add(:after_days, :only_allow_one_purchased_message)
        end
      end
    end
  end
end
