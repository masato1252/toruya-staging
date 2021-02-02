# frozen_string_literal: true

require "sms_client"

module Sms
  class Create < ActiveInteraction::Base
    string :phone_number
    string :message
    object :user, default: nil
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
        user_id: user&.id,
        customer_id: customer&.id,
        reservation_id: reservation&.id,
        rails_env: Rails.configuration.x.env
      )
    end
  end
end
