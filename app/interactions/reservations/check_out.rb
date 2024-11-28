# frozen_string_literal: true

module Reservations
  class CheckOut < ActiveInteraction::Base
    object :reservation

    def execute
      reservation.with_lock do
        unless reservation.may_check_out?
          errors.add(:reservation, :not_checkoutable)
          return
        end

        reservation.check_out!

        reservation.customers.each do |customer|
          customer.update(menu_ids: (customer.menu_ids.concat(reservation.menu_ids.map(&:to_s))).uniq)
        end

        reservation.active_reservation_customers.each do |reservation_customer|
          reservation_customer.customer_tickets.each do |customer_ticket| 
            if customer_ticket.active?
              Notifiers::Customers::Tickets::UnusedTicketLeft.perform_later(
                receiver: reservation_customer.customer,
                customer_ticket: customer_ticket,
                reservation_customer: reservation_customer
              )
            end
          end
        end

        reservation
      end
    end
  end
end
