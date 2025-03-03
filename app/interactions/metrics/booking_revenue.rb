# find the booking revenue for the given period from the booking_page_id order by revenue
# result should be like this
# [
#   {
#     "booking_page_id" => 1,
#     "booking_page_name" => "Booking Page 1",
#     "booking_option_id" => 1,
#     "booking_option_name" => "Booking Option 1",
#     "revenue" => 1000,
#     "count" => 1
#   },
#   {
#     "booking_page_id" => nil, # manual booking
#     "booking_page_name" => "Manual Booking",
#     "booking_option_id" => 2,
#     "booking_option_name" => "Booking Option 2",
#     "revenue" => 2000,
#     "count" => 2
#   }
# ]

module Metrics
  class BookingRevenue < ActiveInteraction::Base
    object :user
    object :metric_period, class: Range

    def execute
      customer_ids = user.customer_ids
      owner_customer_id = user.owner_social_customer&.customer_id
      reservation_ids = Reservation.where(user_id: user.id).where(created_at: metric_period).pluck(:id)
      reservation_customer_scope = ReservationCustomer.where(reservation_id: reservation_ids).where.not(customer_id: owner_customer_id).where(state: [:accepted, :pending])

      # Get bookings with booking options
      booking_reservation_customer_scope = reservation_customer_scope.where.not(booking_page_id: nil)
      booking_option_ids = booking_reservation_customer_scope.pluck(:booking_option_ids).flatten.compact
      booking_option_counts = booking_option_ids.group_by(&:itself).transform_values(&:count)
      booking_option_ids = booking_option_counts.keys
      booking_options = user.booking_options.where(id: booking_option_ids).to_a
      booking_results = booking_option_counts.map do |booking_option_id, count|
      booking_option = booking_options.find { |option| option.id.to_s == booking_option_id.to_s }

        {
          "booking_option_id" => booking_option_id,
          "booking_option_name" => booking_option.name,
          "count" => count,
          "revenue" => count * booking_option.amount_cents
        }
      end

      # Get manual bookings (without booking options)
      # manual_booking_options = user.booking_options.group_by(&:id)
      # manual_reservation_customers = reservation_customer_scope.where(booking_page_id: nil)

      # manual_results = []
      # manual_reservation_customers.joins(:reservation)
      #   .joins("LEFT JOIN reservation_menus ON reservation_menus.reservation_id = reservations.id")
      #   .joins("LEFT JOIN menus ON menus.id = reservation_menus.menu_id")
      #   .joins("LEFT JOIN booking_option_menus ON booking_option_menus.menu_id = menus.id")
      #   .joins("LEFT JOIN booking_options ON booking_options.id = booking_option_menus.booking_option_id")
      #   .group("booking_options.id", "menus.id")
      #   .select(
      #     "booking_options.id as booking_option_id",
      #     "booking_options.name as booking_option_name",
      #     "menus.id as menu_id",
      #     "menus.name as menu_name",
      #     "SUM(booking_options.amount_cents) as revenue",
      #     "COUNT(DISTINCT reservation_customers.id) as count"
      #   ).each do |result|
      #     manual_results << {
      #       "booking_option_id" => result.booking_option_id,
      #       "booking_option_name" => result.menu_name,
      #       "revenue" => result.revenue.to_i,
      #       "count" => result.count.to_i
      #     }
      #   end

      # Combine both results and sort by revenue
      (booking_results).sort_by { |r| -r["revenue"] }
    end
  end
end