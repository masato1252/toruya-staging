# frozen_string_literal: true

module Notifiers
  module Users
    class PendingReservation < Base
      deliver_by_priority [:email]

      object :reservation_customer

      validate :receiver_should_be_user

      def message
        I18n.t("notifier.pending_reservation.message",
          user_name: receiver.name,
          booking_time: reservation.booking_time,
          customer_name: reservation_customer.customer.name,
          reservation_popup_url: reservation.reservation_popup_url
        )
      end

      private

      def reservation
        reservation_customer.reservation
      end
    end
  end
end
