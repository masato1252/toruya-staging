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

      def execute
        if schedule_right_away
          send_schedule_message(custom_message)
        elsif next_custom_messages.exists?
          next_custom_messages.find_each do |next_custom_message|
            send_schedule_message(next_custom_message)
          end
        end
      end

      private

      def send_schedule_message(message)
        schedule_at = message_product.start_at_for_customer(receiver).advance(days: message.after_days).change(hour: 9)

        if schedule_at > Time.current || message.after_days == 0
          # TODO: think about change case
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

        @next_custom_messages = CustomMessage.scenario_of(message_product, scenario || custom_message.scenario)
        after_days = @next_custom_messages.where("after_days > ?", custom_message&.after_days || -100).first&.after_days

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
