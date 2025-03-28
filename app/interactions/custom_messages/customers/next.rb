# frozen_string_literal: true

module CustomMessages
  module Customers
    class Next < ActiveInteraction::Base
      object :custom_message, default: nil
      object :product, default: nil, class: ApplicationRecord
      string :scenario, default: nil
      object :receiver, class: ::Customer
      boolean :schedule_right_away, default: false

      validate :validate_next_scenario

      # Default hour to send messages (in customer's local timezone)
      DEFAULT_NOTIFICATION_HOUR = 9

      def execute
        # Ensure all time operations use the customer's timezone
        Time.use_zone(receiver.timezone) do
          if schedule_right_away
            send_schedule_message(custom_message)
          elsif next_custom_messages.exists?
            next_custom_messages.find_each do |next_custom_message|
              send_schedule_message(next_custom_message)
            end
          end
        end
      end

      private

      def send_schedule_message(message)
        # When there are two 1 day after and two 7 day after custom messages
        # each 1 day after message looking for next custom messages, then that causes total four 7 days after messages in the queues
        # That might causes duplicate message be sent to the same customer
        # Add rand number to make then don't send at the same time to avoid this.

        # Calculate the schedule time in the customer's timezone
        # We're already in the customer's timezone context from the execute method
        base_time = message_product.start_at_for_customer(receiver).advance(days: message.after_days)
        schedule_at = base_time.change(hour: DEFAULT_NOTIFICATION_HOUR, min: rand(5), sec: rand(59))

        # Compare times in the same timezone context
        current_time = Time.current
        if schedule_at > current_time || message.after_days == 0
          Notifiers::Customers::CustomMessages::Send.perform_at(
            schedule_at: schedule_at,
            custom_message: message,
            receiver: receiver
          )
        end
      end

      def message_product
        @message_product ||= product || custom_message.service
      end

      def next_custom_messages
        return @next_custom_messages if defined?(@next_custom_messages)

        @next_custom_messages = CustomMessage.scenario_of(message_product, scenario || custom_message.scenario).where(locale: receiver.locale)
        after_days = @next_custom_messages.where("after_days > ?", custom_message&.after_days || -100).order(:after_days).first&.after_days

        @next_custom_messages =
          if after_days
            @next_custom_messages.where(after_days: after_days)
          else
            @next_custom_messages.none
          end

        @next_custom_messages
      end

      def validate_next_scenario
        if custom_message && (product && scenario)
          errors.add(:custom_message, :invalid_params)
        end

        if !custom_message && !product && !scenario
          errors.add(:custom_message, :invalid_params)
        end
      end
    end
  end
end
