# frozen_string_literal: true

module ReservationCustomers
  class Cancel < ActiveInteraction::Base
    integer :reservation_id
    integer :customer_id

    def execute
      if reservation.customers.count == 1
        compose(Reservations::Cancel, reservation: reservation)
      else
        reservation_customer.canceled!
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
