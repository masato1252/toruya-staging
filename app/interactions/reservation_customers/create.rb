# frozen_string_literal: true

module ReservationCustomers
  class Create < ActiveInteraction::Base
    object :reservation
    hash :customer_data, strip: false

    def execute
      reservation.transaction do
        reservation.reservation_customers.create(customer_data)

        customer = reservation.user.customers.find(customer_data[:customer_id])
        customer.update(menu_ids: (customer.menu_ids.concat(reservation.menu_ids.map(&:to_s))).uniq)
      end
    end
  end
end
