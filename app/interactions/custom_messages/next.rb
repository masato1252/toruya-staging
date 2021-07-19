# frozen_string_literal: true

module CustomMessages
  class Next < ActiveInteraction::Base
    object :custom_message, default: nil
    object :product, default: nil, class: ApplicationRecord
    string :scenario, default: nil
    object :receiver, class: ApplicationRecord

    validate :validate_next_scenario

    def execute
      if next_custom_message
        Notifiers::CustomMessages::Send.perform_at(
          schedule_at: Time.current.advance(days: next_custom_message.after_last_message_days).change(hour: 9),
          custom_message: next_custom_message,
          receiver: receiver
        )
      end
    end

    private

    def next_custom_message
      return @next_custom_message if defined?(@next_custom_message)

      scope = CustomMessage.where(scenario: scenario || custom_message.scenario, service: product || custom_message.service)
      @next_custom_message = scope.where("position > ?", custom_message&.position || -1).first
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
