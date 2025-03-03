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
      manual_booking_options = user.booking_options.group_by(&:id)
      manual_reservation_customers = reservation_customer_scope.where(booking_page_id: nil)
      reservation_ids = manual_reservation_customers.pluck(:reservation_id).flatten.compact
      menu_ids = ReservationMenu.where(reservation_id: reservation_ids).pluck(:menu_id)
      menu_counts = menu_ids.group_by(&:itself).transform_values(&:count)
      menu_ids = menu_counts.keys

      manual_results = menu_counts.map do |menu_id, count|
        menu = Menu.find(menu_id)
        exclusive_booking_option = menu.exclusive_booking_options.first

        if exclusive_booking_option
          {
            "booking_option_id" => exclusive_booking_option.id.to_s,
            "booking_option_name" => exclusive_booking_option.name,
            "count" => count,
            "revenue" => count * exclusive_booking_option.amount_cents
          }
        end
      end.compact
      # Combine both results and sort by revenue
      # Combine results with the same booking_option_id
      combined_results = (booking_results + manual_results).group_by { |r| r["booking_option_id"] }
        .map do |booking_option_id, items|
          {
            "booking_option_id" => booking_option_id,
            "booking_option_name" => items.first["booking_option_name"],
            "count" => items.sum { |item| item["count"] },
            "revenue" => items.sum { |item| item["revenue"] }
          }
        end

      # Sort by revenue in descending order
      combined_results.sort_by { |r| -r["revenue"] }
    end
  end
end