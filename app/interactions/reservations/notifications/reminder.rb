# frozen_string_literal: true

module Reservations
  module Notifications
    class Reminder < Notify
      def execute
        I18n.with_locale(customer.locale) do
          return unless reservation.remind_customer?(customer)

          if customer.email.present?
            CustomerMailer.with(reservation: reservation, customer: customer, email: customer.email, content: message).reservation_reminder.deliver_now
          end

          super
        end
      end

      private

      def message
        @message ||= begin
          booking_page = ReservationCustomer.find_by!(customer: customer, reservation: reservation).booking_page
          template = compose(
            ::CustomMessages::Customers::Template,
            product: booking_page,
            scenario: ::CustomMessages::Customers::Template::BOOKING_PAGE_ONE_DAY_REMINDER,
            custom_message_only: true
          )
  
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
