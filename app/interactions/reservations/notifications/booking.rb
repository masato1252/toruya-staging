# frozen_string_literal: true

require "translator"

module Reservations
  module Notifications
    class Booking < Notify
      string :email, default: nil
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

        super
      end

      private

      def message
        template = compose(
          ::CustomMessages::Customers::Template,
          product: booking_page,
          scenario: ::CustomMessages::Customers::Template::BOOKING_PAGE_BOOKED,
          custom_message_only: true
        )
        template ||= compose(
          ::CustomMessages::Customers::Template,
          product: booking_page.shop,
          scenario: ::CustomMessages::Customers::Template::BOOKING_PAGE_BOOKED
        )

        Translator.perform(template, booking_page.message_template_variables(customer, reservation))
      end
    end
  end
end
