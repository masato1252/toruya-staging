# frozen_string_literal: true

require "random_code"

module IdentificationCodes
  class Create < ActiveInteraction::Base
    string :phone_number
    object :user, default: nil
    object :customer, default: nil

    def execute
      ApplicationRecord.transaction do
        code = RandomCode.generate(6)

        I18n.with_locale(user&.locale || customer&.locale || I18n.locale) do
          booking_code = BookingCode.create!(
            phone_number: phone_number,
            customer_id: customer&.id,
            uuid: SecureRandom.uuid,
            code: code
          )
          message = I18n.t("customer.notifications.sms.confirmation_code", code: code)

          compose(
            Sms::Create,
            user: user,
            message: "Toruya\n#{message}\n#{I18n.t("customer.notifications.noreply")}",
            phone_number: phone_number
          )

          booking_code
        end
      end
    end
  end
end
