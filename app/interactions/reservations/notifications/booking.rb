# frozen_string_literal: true

require "translator"

# pending notification to customer
module Reservations
  module Notifications
    class Booking < Notify
      object :booking_page
      array :booking_options

      def execute
        I18n.with_locale(customer.locale) do
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
