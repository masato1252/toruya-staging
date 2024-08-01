# frozen_string_literal: true

module ReservationCustomers
  class Create < ActiveInteraction::Base
    object :reservation
    hash :customer_data, strip: false

    def execute
      reservation.transaction do
        if reservation_customer = reservation.reservation_customers.create(customer_data)
          ReservationConfirmationJob.perform_later(reservation, reservation_customer.customer) if customer_data[:state] == 'accepted'

          # for cache
          if booking_page = reservation_customer.booking_page
            date_range = reservation.start_time.beginning_of_day..reservation.start_time.tomorrow.end_of_day
            special_dates = booking_page.booking_page_special_dates.where(start_at: date_range).map do |special_date|
              {
                start_at_date_part: special_date.start_at_date,
                start_at_time_part: special_date.start_at_time,
                end_at_date_part:   special_date.end_at_date,
                end_at_time_part:   special_date.end_at_time
              }.to_json
            end

            Booking::Calendar.run(
              shop: booking_page.shop,
              booking_page: booking_page,
              date_range: date_range,
              booking_option_ids: booking_page.booking_option_ids,
              special_dates: special_dates,
              special_date_type: booking_page.booking_page_special_dates.exists?,
              interval: booking_page.interval,
              overbooking_restriction: booking_page.overbooking_restriction
            )
          end
        end
      end
    end
  end
end
