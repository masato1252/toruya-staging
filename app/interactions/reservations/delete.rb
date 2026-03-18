# frozen_string_literal: true

module Reservations
  class Delete < ActiveInteraction::Base
    object :reservation

    def execute
      reservation.transaction do
        reservation.reservation_customers.each do |rc|
          rc.customer_tickets.each do |customer_ticket|
            compose(Tickets::Revert, consumer: rc, customer_ticket: customer_ticket)
          end
        end

        reservation.update_columns(deleted_at: Time.current)
        reservation.reservation_customers.update_all(state: :deleted)
      end
    end
  end
end
