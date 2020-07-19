require "sms_client"

module Sms
  class Create < ActiveInteraction::Base
    object :user
    string :phone_number
    string :message
    object :customer, default: nil
    object :reservation, default: nil

    def execute
      SmsClient.send(phone_number, message)

      Notification.create!(
        user: user,
        phone_number: phone_number,
        content: message,
        customer_id: customer&.id,
        reservation_id: reservation&.id
      )
    rescue Twilio::REST::RestError => e
      Rollbar.error(
        e,
        phone_numbers: phone_number,
        customer_id: customer&.id,
        reservation_id: reservation&.id,
        rails_env: Rails.configuration.x.env
      )
    end
  end
end
