# frozen_string_literal: true

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
        template = ::CustomMessages::Template.run!(product: booking_page, scenario: ::CustomMessages::Template::BOOKING_PAGE_BOOKED)

        Translator.perform(template, booking_page.message_template_variables(customer, reservation))
      end
    end
  end
end
