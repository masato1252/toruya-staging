# frozen_string_literal: true

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
        template = I18n.t(
          "customer.notifications.sms.confirmation",
          customer_name: customer.name,
          shop_name: shop.display_name,
          booking_time: "#{I18n.l(reservation.start_time, format: :long_date_with_wday)} ~ #{I18n.l(reservation.end_time, format: :time_only)}"
        )

        if shop.phone_number.present?
          template = "#{template}#{I18n.t("customer.notifications.sms.change_from_phone_number", shop_phone_number: shop.phone_number)}"
        end

        template
      end
    end
  end
end
