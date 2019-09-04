module Booking
  module Notifications
    class SendCustomerSms < ActiveInteraction::Base
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

        # XXX: Japan dependency
        Twilio::REST::Client.new.messages.create(
          from: Rails.application.secrets.twilio_from_phone,
          to: Phonelib.parse(phone_number, "jp").international(true),
          body: message
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
