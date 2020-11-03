module Notifiers
  module Booking
    class ShopOwnerReservationBookedNotification < Base
      deliver_by_priority [:line, :sms, :email]

      object :reservation
      object :booking_page
      object :booking_option

      def message
        I18n.t(
          "notifier.booking.shop_owner_reservation_booked_notification.message",
          user_name: receiver.name,
          booking_page_title: booking_page.title
        )
      end

      def send_email
        BookingMailer.with(
          customer: customer,
          reservation: reservation,
          booking_page: booking_page,
          booking_option: booking_option,
        ).shop_owner_reservation_booked_notification.deliver_now
      end

      private

      def shop
        @shop ||= booking_page.shop
      end

      def reservation_customer
        @reservation_customer ||= reservation.reservation_customers.find_by(customer_id: @customer.id)
      end
    end
  end
end
