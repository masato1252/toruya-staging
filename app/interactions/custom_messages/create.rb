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
        when nil
          # For customers purchaed/booked, so do nothing when this custom message was created
        when 0
          if service.custom_messages.where(scenario: scenario).count == 1
            # Send all customers already purchased
            service.available_customers.find_each do |customer|
              Notifiers::CustomMessages::Send.perform_later(
                custom_message: message,
                receiver: customer
              )
            end
          end
        else
          # Send this new message to last custom message receiver_ids
          last_message = CustomMessage.where("after_days < ?", after_days).find_by(service: service, scenario: scenario)

          if last_message
            service.available_customers.where(id: last_message.receiver_ids).find_each do |customer|
              CustomMessages::Next.perform_later(
                custom_message: message,
                receiver: customer
              )
            end
          end
        end
      end

      message.save
      message
    end
  end
end
