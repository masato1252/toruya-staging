module ReservationCustomers
  class Cancel < ActiveInteraction::Base
    integer :reservation_id
    integer :customer_id

    def execute
      reservation_customer.canceled!
      reservation_customer.reservation.try_accept
    end

    private

    def reservation_customer
      ReservationCustomer.find_by!(reservation_id: reservation_id, customer_id: customer_id)
    end
  end
end
