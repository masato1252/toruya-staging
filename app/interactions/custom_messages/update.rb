# frozen_string_literal: true

module CustomMessages
  class Update < ActiveInteraction::Base
    object :service, class: ApplicationRecord
    string :template
    string :scenario
    integer :position
    integer :after_last_message_days

    def execute
      message = CustomMessage.find_or_initialize_by(
        service: service,
        scenario: scenario,
        position: position
      )
      message.content = template

      if message.valid? && message.new_record? && service.is_a?(OnlineService)
        message.save

        case message.position
        when 0
          # For customers purchaed/booked, so do nothing when this custom message was created
        when 1
          # Send all customers already purchased
          service.available_customers.find_each do |customer|
            Notifiers::CustomMessages::Send.perform_later(
              custom_message: message,
              receiver: customer
            )
          end
        else
          # Send this new message to last custom message receiver_ids
          last_message = CustomMessage.find_by(service: service, scenario: scenario, position: position - 1)

          service.available_customers.where(id: last_message.receiver_ids).find_each do |customer|
            CustomMessages::Next.perform_later(
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
