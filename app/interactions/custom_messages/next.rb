# frozen_string_literal: true

module CustomMessages
  class Next < ActiveInteraction::Base
    object :custom_message, default: nil
    object :product, default: nil, class: ApplicationRecord
    string :scenario, default: nil
    object :receiver, class: ApplicationRecord

    validate :validate_next_scenario

    def execute
      if next_custom_messages&.exists?
        next_custom_messages.find_each do |next_custom_message|
          schedule_at = message_product.start_at_for_customer(receiver).advance(days: next_custom_message.after_days).change(hour: 9)

          if schedule_at > Time.current || next_custom_message.after_days == 0
            Notifiers::CustomMessages::Send.perform_at(
              schedule_at: schedule_at,
              custom_message: next_custom_message,
              receiver: receiver
            )
          end
        end
      end
    end

    private

    def message_product
      @message_product ||= product || custom_message.service
    end

    def next_custom_messages
      return @next_custom_message if defined?(@next_custom_message)

      scope = CustomMessage.where(scenario: scenario || custom_message.scenario, service: message_product)
      after_days = scope.where("after_days > ?", custom_message&.after_days || -100).first&.after_days
      scope.where(after_days: after_days) if after_days
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
