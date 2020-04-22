module Reservations
  module Notifications
    class Booking < Notify
      string :email
      object :booking_page
      object :booking_option

      def execute
        # XXX: Use the email using at booking time
        if email.present?
          BookingMailer.with(
            customer: customer,
            reservation: reservation,
            booking_page: booking_page,
            booking_option: booking_option,
            email: email
          ).customer_reservation_notification.deliver_later
        end

        BookingMailer.with(
          customer: customer,
          reservation: reservation,
          booking_page: booking_page,
          booking_option: booking_option,
        ).shop_owner_reservation_booked_notification.deliver_later

        super
      end

      private

      def message
        I18n.t(
          "customer.notifications.sms.booking",
          customer_name: customer.name,
          shop_name: shop.display_name,
          shop_phone_number: shop.phone_number,
          booking_time: "#{I18n.l(reservation.start_time, format: :long_date_with_wday)} ~ #{I18n.l(reservation.end_time, format: :time_only)}"
        )
      end
    end
  end
end
