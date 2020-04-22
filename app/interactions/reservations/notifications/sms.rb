require "sms"

module Reservations
  module Notifications
    class Sms < ActiveInteraction::Base
      string :phone_number
      object :customer
      object :reservation
      string :message

      def execute
        ::Sms.send(phone_number, "#{message}#{I18n.t("customer.notifications.noreply")}")

        Notification.create!(
          user: customer.user,
          phone_number:  phone_number,
          customer_id: customer.id,
          reservation_id: reservation.id,
          content: message
        )
      rescue Twilio::REST::RestError => e
        Rollbar.error(
          e,
          phone_numbers: phone_number,
          formatted_phone: formatted_phone,
          customer_id: customer.id,
          reservation_id: reservation.id,
          rails_env: Rails.configuration.x.env
        )
      end

      private

      def shop
        @shop ||= reservation.shop
      end
    end
  end
end
