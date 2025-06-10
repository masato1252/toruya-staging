# frozen_string_literal: true

# reservation reminder to customer
module Reservations
  module Notifications
    class Reminder < Notify
      def execute
        I18n.with_locale(customer.locale) do
          return unless reservation.remind_customer?(customer)

          super
        end
      end

      private

      def message
        @message ||= begin
          reservation_customer = ReservationCustomer.find_by!(customer: customer, reservation: reservation)
          booking_page = reservation_customer.booking_page
          activity = reservation_customer.survey_activity

          if booking_page
            # Determine which message to use based on the setting
            if booking_page.use_shop_default_message
              # Use shop default message
              template = compose(
                ::CustomMessages::Customers::Template,
                product: reservation.shop,
                scenario: ::CustomMessages::Customers::Template::RESERVATION_ONE_DAY_REMINDER
              )
            else
              # Use booking page custom message
            template = compose(
              ::CustomMessages::Customers::Template,
              product: booking_page,
              scenario: ::CustomMessages::Customers::Template::BOOKING_PAGE_ONE_DAY_REMINDER,
              custom_message_only: true
            )
            end
          end

          if activity
            template ||= compose(
              ::CustomMessages::Customers::Template,
              product: activity.survey,
              scenario: ::CustomMessages::Customers::Template::ACTIVITY_ONE_DAY_REMINDER
            )
          end

          # Only use shop default message as fallback when no template is set above
          template ||= compose(
            ::CustomMessages::Customers::Template,
            product: reservation.shop,
            scenario: ::CustomMessages::Customers::Template::RESERVATION_ONE_DAY_REMINDER
          )

          Translator.perform(template, reservation.message_template_variables(customer))
        end
      end
    end
  end
end
