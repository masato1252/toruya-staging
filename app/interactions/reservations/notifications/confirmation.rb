module Reservations
  module Notifications
    class Confirmation < Notify
      def execute
        if customer.email.present?
          CustomerMailer.with(reservation: reservation, customer: customer, email: customer.email).reservation_confirmation.deliver_now
        end

        super
      end

      private

      def message
        I18n.t(
          "customer.notifications.sms.confimation",
          customer_name: customer.name,
          shop_name: shop.display_name,
          shop_phone_number: shop.phone_number,
          booking_time: "#{I18n.l(reservation.start_time, format: :long_date_with_wday)} ~ #{I18n.l(reservation.end_time, format: :time_only)}"
        )
      end
    end
  end
end
