module Booking
  class AvailableBookingTimes < ActiveInteraction::Base
    object :shop
    # booking_option_ids
    # ["1"]
    array :booking_option_ids
    # special_dates
    # [
    # "{\"start_at_date_part\":\"2019-05-06\",\"start_at_time_part\":\"01:00\",\"end_at_date_part\":\"2019-05-06\",\"end_at_time_part\":\"12:59\"}",
    # "{\"start_at_date_part\":\"2019-05-23\",\"start_at_time_part\":\"01:00\",\"end_at_date_part\":\"2019-05-23\",\"end_at_time_part\":\"12:59\"}"
    # ]
    array :special_dates
    integer :interval
    boolean :overlap_restriction, default: true
    integer :limit, default: nil

    def execute
      available_booking_time_mapping = {}

      catch :enough_booking_time do
        special_dates.each do |raw_special_date|
          available_booking_times = []

          json_parsed_date = JSON.parse(raw_special_date)
          special_date = Date.parse(json_parsed_date["start_at_date_part"])

          booking_start_at = special_date_start_at = Time.zone.parse("#{json_parsed_date["start_at_date_part"]}-#{json_parsed_date["start_at_time_part"]}")
          special_date_end_at = Time.zone.parse("#{json_parsed_date["end_at_date_part"]}-#{json_parsed_date["end_at_time_part"]}")

          shop.user.booking_options.where(id: booking_option_ids).includes(:menus).each do |booking_option|
            loop do
              booking_end_at = booking_start_at.advance(minutes: booking_option.minutes)

              if booking_end_at > special_date_end_at

                break
              end

              valid_menus = []

              booking_option.menus.each do |menu|
                active_staff_ids = menu.active_staff_ids & shop.staff_ids
                # XXX Avoid no manpower menu(min_staffs_number is 0) don't validate staffs
                required_staffs_number = [menu.min_staffs_number, 1].max

                active_staff_ids.combination(required_staffs_number).each do |candidate_staff_ids|
                  reserable_outcome = Reservable::Reservation.run(
                    shop: shop,
                    date: booking_start_at.to_date,
                    business_time_range: booking_start_at..booking_end_at,
                    booking_option_id: booking_option.id,
                    menu_id: menu.id,
                    staff_ids: candidate_staff_ids,
                    overlap_restriction: overlap_restriction
                  )

                  if reserable_outcome.valid?
                    valid_menus << menu

                    # all menus got staffs to handle
                    if booking_option.menus.count == valid_menus.length
                      # Rails.logger.info("====#{booking_start_at.to_s}~#{booking_end_at.to_s(:time)}========")

                      available_booking_times << booking_start_at

                      available_booking_time_mapping[booking_start_at] ||= []
                      available_booking_time_mapping[booking_start_at] << booking_option.id

                      throw :enough_booking_time if limit && available_booking_times.length >= limit
                    end
                  end
                end
              end

              booking_start_at = booking_start_at.advance(minutes: interval)
            end
          end
        end
      end

      available_booking_time_mapping
    end
  end
end
