require "sms_client"

module Booking
  class Code < ActiveInteraction::Base
    CODE_CHARSET = (1..9).to_a.freeze

    object :booking_page
    string :first_name
    string :last_name
    string :phone_number

    def execute
      ApplicationRecord.transaction do
        code = generate_code(6)

        booking_code = BookingCode.create!(
          booking_page_id: booking_page.id,
          uuid: SecureRandom.uuid,
          code: code
        )
        message = I18n.t("customer.notifications.sms.confirmation_code", customer_name: "#{last_name} #{first_name}", code: code)

        # SmsClient.send(phone_number, "#{message}#{I18n.t("customer.notifications.noreply")}")

        Notification.create!(
          user: booking_page.user,
          phone_number:  phone_number,
          content: message
        )

        booking_code
      rescue Twilio::REST::RestError => e
        Rollbar.error(
          e,
          phone_numbers: phone_number,
          first_name: first_name,
          last_name: last_name,
          rails_env: Rails.configuration.x.env
        )
      end
    end

    private

    def generate_code(number)
      Array.new(number) { CODE_CHARSET.sample }.join
    end
  end
end
