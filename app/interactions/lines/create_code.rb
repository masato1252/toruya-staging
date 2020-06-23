require "sms_client"
require "random_code"

module Lines
  class CreateCode < ActiveInteraction::Base
    object :user
    string :phone_number

    def execute
      ApplicationRecord.transaction do
        code = RandomCode.generate(6)

        booking_code = BookingCode.create!(
          uuid: SecureRandom.uuid,
          code: code
        )
        message = I18n.t("customer.notifications.sms.confirmation_code", code: code)

        begin
          SmsClient.send(phone_number, "#{message}\n#{I18n.t("customer.notifications.noreply")}")
        rescue Twilio::REST::RestError => e
          Rollbar.error(
            e,
            phone_numbers: phone_number,
            rails_env: Rails.configuration.x.env
          )
        end

        Notification.create!(
          user: user,
          phone_number: phone_number,
          content: message
        )

        booking_code
      end
    end
  end
end
