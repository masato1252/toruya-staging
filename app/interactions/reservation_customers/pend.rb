module ReservationCustomers
  class Pend < ActiveInteraction::Base
    integer :reservation_id
    integer :customer_id

    def execute
      reservation_customer.pending!
      reservation = reservation_customer.reservation
      reservation.pend!
    end

    private

    def reservation_customer
      ReservationCustomer.find_by!(reservation_id: reservation_id, customer_id: customer_id)
    end
  end
end
