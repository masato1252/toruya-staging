require "random_code"

module Booking
  class CreateCode < ActiveInteraction::Base
    object :booking_page
    string :phone_number

    def execute
      ApplicationRecord.transaction do
        code = RandomCode.generate(6)

        booking_code = BookingCode.create!(
          phone_number: phone_number,
          booking_page_id: booking_page.id,
          uuid: SecureRandom.uuid,
          code: code
        )
        message = I18n.t("customer.notifications.sms.confirmation_code", code: code)

        compose(
          Sms::Create,
          user: booking_page.user,
          message: "#{message}\n#{I18n.t("customer.notifications.noreply")}(#{booking_page.name})",
          phone_number: phone_number
        )

        booking_code
      end
    end
  end
end
