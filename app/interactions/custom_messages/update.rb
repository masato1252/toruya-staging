# frozen_string_literal: true

module CustomMessages
  class Update < ActiveInteraction::Base
    object :message, class: CustomMessage
    string :template
    integer :after_days, default: nil

    validate :validate_purchased_message
    validate :validate_after_days

    def execute
      message.content = template
      message.after_days = after_days

      if message.valid? && message.service.is_a?(OnlineService) && message.after_days_changed?
        message.save

        case message.after_days
        when nil, 0
          # For customers purchaed/booked, so do nothing when this custom message was created
        else
          message.service.available_customers.find_each do |customer|
            ::CustomMessages::Next.perform_later(
              custom_message: message,
              receiver: customer
            )
          end
        end
      end

      message.save
      message
    end

    private

    def validate_purchased_message
      if after_days.nil? && CustomMessage.scenario_of(message.service, message.scenario).right_away.where.not(id: message.id).exists?
        errors.add(:after_days, :only_allow_one_purchased_message)
      end
    end

    def validate_after_days
      if !after_days.nil? && after_days < 0
        errors.add(:after_days, :need_to_be_positive)
      end
    end
  end
end
