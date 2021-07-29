# frozen_string_literal: true

module Reservations
  module Notifications
    class Reminder < Notify
      def execute
        if customer.email.present?
          CustomerMailer.with(reservation: reservation, customer: customer, email: customer.email).reservation_reminder.deliver_now
        end

        super
      end

      private

      def message
        booking_page = ReservationCustomer.find_by!(customer: customer, reservation: reservation).booking_page
        template = CustomMessage.template_of(booking_page, CustomMessage::BOOKING_PAGE_ONE_DAY_REMINDER)

        Translator.perform(template, {
          customer_name: customer.name,
          shop_name: reservation.shop.display_name,
          shop_phone_number: reservation.shop.phone_number,
          booking_time: "#{I18n.l(reservation.start_time, format: :long_date_with_wday)} ~ #{I18n.l(reservation.end_time, format: :time_only)}"
        })
      end
    end
  end
end
