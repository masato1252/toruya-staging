module Booking
  class Calendar < ActiveInteraction::Base
    object :shop
    object :date_range, class: Range
    # booking_option_ids
    # ["1"]
    array :booking_option_ids, default: nil
    # special_dates
    # [
    # "{\"start_at_date_part\":\"2019-05-06\",\"start_at_time_part\":\"01:00\",\"end_at_date_part\":\"2019-05-06\",\"end_at_time_part\":\"12:59\"}",
    # "{\"start_at_date_part\":\"2019-05-23\",\"start_at_time_part\":\"01:00\",\"end_at_date_part\":\"2019-05-23\",\"end_at_time_part\":\"12:59\"}"
    # ]
    array :special_dates, default: nil
    integer :interval, default: 30

    def execute
      rules = compose(Shops::WorkingCalendarRules, shop: shop, date_range: date_range)
      schedules = compose(CalendarSchedules::Create, rules: rules, date_range: date_range)
      available_booking_dates = []

      if special_dates
        available_booking_dates = special_dates.map do |special_date|
          # {"start_at_date_part"=>"2019-05-06", "start_at_time_part"=>"01:00", "end_at_date_part"=>"2019-05-06", "end_at_time_part"=>"12:59"}
          JSON.parse(special_date)["start_at_date_part"]
        end
      else
        booking_options = compose(
          BookingOptions::Prioritize,
          booking_options: shop.user.booking_options.where(id: booking_option_ids).includes(:menus)
        )

        schedules[:working_dates].each do |date|
          time_range_outcome = Reservable::Time.run(shop: shop, date: date)
          next if time_range_outcome.invalid?

          time_range = time_range_outcome.result
          booking_start_at = shop_open_at = time_range.first
          shop_close_at = time_range.last

          catch :next_working_date do
            booking_options.each do |booking_option|
              # the booking reservation need at least booking_option.minutes + booking_option.interval
              # but as more as possible booking_option.interval * 2
              booking_end_at = booking_start_at.advance(minutes: booking_option.minutes + booking_option.interval * 2)

              if booking_end_at > shop_close_at
                booking_end_at = booking_start_at.advance(minutes: booking_option.minutes + booking_option.interval)

                if booking_end_at > shop_close_at
                  next
                else
                  booking_end_at = shop_close_at
                end
              end

              loop do
                valid_menus = []

                booking_option.menus.each do |menu|
                  active_staff_ids = menu.active_staff_ids & shop.staff_ids

                  active_staff_ids.combination(menu.min_staffs_number).each do |candidate_staff_ids|
                    reserable_outcome = Reservable::Reservation.run(
                      shop: shop,
                      date: date,
                      business_time_range: booking_start_at..booking_end_at,
                      menu_ids: [menu.id],
                      staff_ids: candidate_staff_ids
                    )

                    if reserable_outcome.valid?
                      valid_menus << menu

                      # all menus got staffs to handle
                      if booking_option.menus.count == valid_menus.length
                        available_booking_dates << date

                        throw :next_working_date
                      end
                    else
                      # test next staff
                      next
                    end
                  end
                end

                booking_start_at = booking_start_at.advance(minutes: interval)
                booking_end_at = booking_start_at.advance(minutes: booking_option.minutes + booking_option.interval)

                break if booking_end_at > shop_close_at
              end
            end
          end
        end
      end

      [
        schedules,
        available_booking_dates
      ]
    end
  end
end
