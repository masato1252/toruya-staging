module ReservationCustomers
  class Pend < ActiveInteraction::Base
    object :reservation
    object :customer

    def execute
      reservation_customer.pending!
      reservation_customer.reservation.try_accept
    end

    private

    def reservation_customer
      ReservationCustomer.find_by!(reservation_id: reservation_id, customer_id: customer_id)
    end
  end
end
