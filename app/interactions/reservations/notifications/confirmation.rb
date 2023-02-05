# frozen_string_literal: true

module Reservations
  module Notifications
    class Confirmation < Notify
      def execute
        return if reservation.start_time < Time.current

        if customer.email.present?
          CustomerMailer.with(reservation: reservation, customer: customer, email: customer.email).reservation_confirmation.deliver_now
        end

        super
      end

      private

      def message
        reservation_customer = ReservationCustomer.where(reservation: reservation, customer: customer).first
        template = compose(
          ::CustomMessages::Customers::Template,
          product: reservation_customer.booking_page,
          scenario: ::CustomMessages::Customers::Template::RESERVATION_CONFIRMED,
          custom_message_only: true
        )

        template ||= compose(
          ::CustomMessages::Customers::Template,
          product: reservation.shop,
          scenario: ::CustomMessages::Customers::Template::RESERVATION_CONFIRMED
        )

        Translator.perform(template, reservation.message_template_variables(customer))
      end
    end
  end
end
