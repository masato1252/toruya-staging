# frozen_string_literal: true

module ReservationCustomers
  class Create < ActiveInteraction::Base
    object :reservation
    hash :customer_data, strip: false

    def execute
      reservation.transaction do
        if reservation_customer = reservation.reservation_customers.create(customer_data)
          ReservationConfirmationJob.perform_later(reservation, reservation_customer.customer) if customer_data[:state] == 'accepted'
        end
      end
    end
  end
end
