require "random_code"

module IdentificationCodes
  class CreateForUser < ActiveInteraction::Base
    string :phone_number

    def execute
      ApplicationRecord.transaction do
        code = RandomCode.generate(6)

        booking_code = BookingCode.create!(
          uuid: SecureRandom.uuid,
          code: code
        )

        message = I18n.t("customer.notifications.sms.confirmation_code", code: code)

        compose(
          Sms::Create,
          message: "#{message}\n#{I18n.t("customer.notifications.noreply")}",
          phone_number: phone_number
        )

        booking_code
      end
    end
  end
end
