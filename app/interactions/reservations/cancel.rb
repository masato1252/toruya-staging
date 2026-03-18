# frozen_string_literal: true

module Reservations
  class Cancel < ActiveInteraction::Base
    object :reservation

    def execute
      reservation.transaction do
        reservation.reservation_customers.each do |rc|
          rc.customer_tickets.each do |customer_ticket|
            compose(Tickets::Revert, consumer: rc, customer_ticket: customer_ticket)
          end
        end

        reservation.cancel!
        reservation.reservation_customers.update_all(state: :canceled)
      end
    end
  end
end
