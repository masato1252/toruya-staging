# frozen_string_literal: true

module ReservationCustomers
  class Accept < ActiveInteraction::Base
    integer :reservation_id
    integer :customer_id

    def execute
      reservation_customer.accepted!
    end

    private

    def reservation_customer
      ReservationCustomer.find_by!(reservation_id: reservation_id, customer_id: customer_id)
    end
  end
end
