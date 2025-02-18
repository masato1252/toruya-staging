# frozen_string_literal: true

module Notifiers
  module Customers
    module Tickets
      class UnusedTicketLeft < Base
        object :customer_ticket
        object :reservation_customer

        validate :receiver_should_be_customer

        def message
          I18n.t(
            "notifier.tickets.unused_ticket_left.message",
            ticket_remaining_quota: ticket_remaining_quota,
            ticket_expire_date: ticket_expire_date,
            product_name: product_name,
            booking_page_url: booking_page_url
          )
        end

        private

        def ticket_remaining_quota
          customer_ticket.remaining_quota
        end

        def ticket_expire_date
          I18n.l(customer_ticket.expire_at, format: :date)
        end

        def product_name
          customer_ticket.ticket.ticket_products.map(&:product).map(&:display_name).to_sentence
        end

        def booking_page_url
          url_helpers.booking_page_url(reservation_customer.booking_page.slug, last_booking_option_ids: reservation_customer.booking_option_ids.join(","))
        end
      end
    end
  end
end
