# frozen_string_literal: true

module ReservationCustomers
  class Cancel < ActiveInteraction::Base
    integer :reservation_id
    integer :customer_id

    def execute
      reservation_customer.canceled!

      unless reservation.customers.exists?
        compose(Reservations::Cancel, reservation: Reservation.find(reservation_id))
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
