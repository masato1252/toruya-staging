module CustomMessages
  class Create < ActiveInteraction::Base
    object :service, class: ApplicationRecord
    string :template
    string :scenario
    integer :after_days, default: nil

    def execute
      message = CustomMessage.create(
        service: service,
        scenario: scenario,
        content: template,
        after_days: after_days
      )

      if message.valid? && service.is_a?(OnlineService)
        message.save

        case message.after_days
        when nil, 0
          # For customers purchaed/booked, so do nothing when this custom message was created
        else
          service.available_customers.find_each do |customer|
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
