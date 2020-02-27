module Reservations
  module Notifications
    class SendCustomerSms < ActiveInteraction::Base
      LAKE_PHONE = "886910819086"
      HARUKO_PHONE = "08036238534"
      string :phone_number
      object :customer
      object :reservation

      def execute
        message = I18n.t(
          "booking_page.notifications.sms",
          customer_name: customer.name,
          shop_name: shop.display_name,
          shop_phone_number: shop.phone_number,
          booking_time: "#{I18n.l(reservation.start_time, format: :date_with_wday)} ~ #{I18n.l(reservation.end_time, format: :time_only)}"
        )

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
          body: "#{message}#{I18n.t("booking_page.notifications.noreply")}"
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
