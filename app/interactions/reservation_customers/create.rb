# frozen_string_literal: true

module ReservationCustomers
  class Create < ActiveInteraction::Base
    object :reservation
    hash :customer_data, strip: false

    def execute
      reservation.transaction do
        if reservation_customer = reservation.reservation_customers.create(customer_data.merge!(slug: SecureRandom.alphanumeric(10)))
          ReservationConfirmationJob.perform_later(reservation, reservation_customer.customer) if customer_data[:state] == 'accepted'
          # for cache
          if booking_page = reservation_customer.booking_page
            ::Booking::Cache.perform_later(booking_page: booking_page, date: reservation.start_time.to_date)
          end
        end
      end
    end
  end
end
