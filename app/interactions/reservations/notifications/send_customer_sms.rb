module Reservations
  module Notifications
    class SendCustomerSms < ActiveInteraction::Base
      LAKE_PHONE = "886910819086"
      HARUKO_PHONE = "08036238534"
      string :phone_number
      object :customer
      object :reservation
      string :message

      def execute
        formatted_phone =
          if Rails.env.development?
            Phonelib.parse(LAKE_PHONE).international(true)
          elsif Rails.configuration.x.env.staging?
            Phonelib.parse(HARUKO_PHONE, "jp").international(true)
          else
            Phonelib.parse(phone_number, "jp").international(true)
          end

        # XXX: Japan dependency
        Twilio::REST::Client.new.messages.create(
          from: Rails.application.secrets.twilio_from_phone,
          to: formatted_phone,
          body: "#{message}#{I18n.t("customer.notifications.noreply")}"
        )

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
