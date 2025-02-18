# frozen_string_literal: true

module Reservations
  module Notifications
    class Sms < ActiveInteraction::Base
      string :phone_number
      object :customer
      object :reservation
      string :message

      def execute
        I18n.with_locale(customer.locale) do
          compose(
            ::Sms::Create,
            user: customer.user,
            message: message,
            phone_number: phone_number,
            reservation: reservation,
            customer: customer
          )
        end
      end
    end
  end
end
