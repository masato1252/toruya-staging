# frozen_string_literal: true

module ReservationCustomers
  class Accept < ActiveInteraction::Base
    object :current_staff, class: Staff
    integer :reservation_id
    integer :customer_id

    def execute
      reservation_customer.accepted!

      unless reservation.customers.exists?
        compose(Reservations::Accept, reservation: reservation, current_staff: current_staff)
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
