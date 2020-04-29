require "sms_client"

module Booking
  class CreateCode < ActiveInteraction::Base
    CODE_CHARSET = (1..9).to_a.freeze

    object :booking_page
    string :phone_number

    def execute
      ApplicationRecord.transaction do
        code = generate_code(6)

        booking_code = BookingCode.create!(
          booking_page_id: booking_page.id,
          uuid: SecureRandom.uuid,
          code: code
        )
        message = I18n.t("customer.notifications.sms.confirmation_code", code: code)

        begin
          SmsClient.send(phone_number, "#{message}\n#{I18n.t("customer.notifications.noreply")}(#{booking_page.name})")
        rescue Twilio::REST::RestError => e
          Rollbar.error(
            e,
            phone_numbers: phone_number,
            rails_env: Rails.configuration.x.env
          )
        end

        Notification.create!(
          user: booking_page.user,
          phone_number:  phone_number,
          content: message
        )

        booking_code
      end
    end

    private

    def generate_code(number)
      Array.new(number) { CODE_CHARSET.sample }.join
    end
  end
end
