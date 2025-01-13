# frozen_string_literal: true

require "translator"

module Reservations
  module Notifications
    class Booking < Notify
      string :email, default: nil
      object :booking_page
      array :booking_options

      def execute
        I18n.with_locale(customer.locale) do
          # XXX: Use the email using at booking time
          # if email.present?
          #   BookingMailer.with(
          #     customer: customer,
          #     reservation: reservation,
          #     booking_page: booking_page,
          #     booking_options: booking_options,
          #     email: email
          #   ).customer_reservation_notification.deliver_later
          # end

          super
        end
      end

      private

      def message
        template = compose(
          ::CustomMessages::Customers::Template,
          product: booking_page,
          scenario: ::CustomMessages::Customers::Template::BOOKING_PAGE_BOOKED,
          custom_message_only: true
        )
        template = compose(
          ::CustomMessages::Customers::Template,
          product: booking_page.shop,
          scenario: ::CustomMessages::Customers::Template::BOOKING_PAGE_BOOKED
        ) if template.blank?

        Translator.perform(template, reservation.message_template_variables(customer))
      end
    end
  end
end
