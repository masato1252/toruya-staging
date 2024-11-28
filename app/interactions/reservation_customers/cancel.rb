# frozen_string_literal: true

# TODO
# handle ticket
# cancel, deleted, refund
module ReservationCustomers
  class Cancel < ActiveInteraction::Base
    integer :reservation_id
    integer :customer_id

    def execute
      reservation_customer.with_lock do
        reservation_customer.canceled!

        reservation_customer.customer_tickets.each do |customer_ticket|
          compose(Tickets::Revert, consumer: reservation_customer, customer_ticket: customer_ticket)
        end

        if reservation.customers.count.zero?
          compose(Reservations::Cancel, reservation: reservation)
        end
      end
    end

    private

    def reservation
      @reservation ||= Reservation.find(reservation_id)
    end

    def reservation_customer
      ReservationCustomer.find_by!(reservation_id: reservation_id, customer_id: customer_id)
    end
  end
end
