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
      SmsClient.send(phone_number, message, user&.locale || customer&.locale || "ja")

      if customer
        SocialMessage.create!(
          social_account: customer.social_customer&.social_account,
          social_customer: customer.social_customer,
          customer_id: customer.id,
          user_id: customer.user_id,
          raw_content: message,
          content_type: "text",
          readed_at: Time.current,
          sent_at: Time.current,
          message_type: "bot",
          channel: SocialMessage.channels[:sms]
        )
      end

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
