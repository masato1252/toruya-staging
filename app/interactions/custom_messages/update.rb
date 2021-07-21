# frozen_string_literal: true

module CustomMessages
  class Update < ActiveInteraction::Base
    object :message, class: CustomMessage
    string :template
    integer :after_days, default: nil

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
  end
end
