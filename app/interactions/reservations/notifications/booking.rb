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
        template = if booking_page.use_shop_default_message
            compose(
              ::CustomMessages::Customers::Template,
              product: booking_page.shop,
              scenario: ::CustomMessages::Customers::Template::BOOKING_PAGE_BOOKED
            )
          else
            compose(
              ::CustomMessages::Customers::Template,
              product: booking_page,
              scenario: ::CustomMessages::Customers::Template::BOOKING_PAGE_BOOKED,
              custom_message_only: true
            )
          end

        Translator.perform(template, reservation.message_template_variables(customer))
      end
    end
  end
end
