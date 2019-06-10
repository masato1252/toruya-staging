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
    boolean :overlap_restriction, default: true

    def execute
      rules = compose(::Shops::WorkingCalendarRules, shop: shop, date_range: date_range)
      schedules = compose(CalendarSchedules::Create, rules: rules, date_range: date_range)
      available_booking_dates = []

      available_booking_dates =
        if special_dates.present?
          special_dates.map do |special_date|
            # {"start_at_date_part"=>"2019-05-06", "start_at_time_part"=>"01:00", "end_at_date_part"=>"2019-05-06", "end_at_time_part"=>"12:59"}
            JSON.parse(special_date)["start_at_date_part"]
          end
        else
          booking_options = compose(
            BookingOptions::Prioritize,
            booking_options: shop.user.booking_options.where(id: booking_option_ids).includes(:menus)
          )

          if Rails.env.test?
            schedules[:working_dates].map do |date|
              test_available_booking_date(booking_options, date)
            end.compact
          else
            # XXX: Parallel doesn't work properly in test mode,
            # some data might be stay in transaction of test thread and would lost in test while using Parallel.
            Parallel.map(schedules[:working_dates]) do |date|
              test_available_booking_date(booking_options, date)
            end.compact
          end
        end

      [
        schedules,
        available_booking_dates
      ]
    end

    private

    def test_available_booking_date(booking_options, date)
      time_range_outcome = Reservable::Time.run(shop: shop, date: date)
      return if time_range_outcome.invalid?

      time_range = time_range_outcome.result
      shop_close_at = time_range.last

      catch :next_working_date do
        booking_options.each do |booking_option|
          # booking_option doesn't sell on that date
          if booking_option.start_time.to_date > Date.parse(date) ||
              booking_option.end_at && booking_option.end_at.to_date < Date.parse(date)
            next
          end

          booking_start_at = shop_open_at = time_range.first

          loop do
            booking_end_at = booking_start_at.advance(minutes: booking_option.minutes)

            if booking_end_at > shop_close_at
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
                  date: date,
                  business_time_range: booking_start_at..booking_end_at,
                  booking_option_id: booking_option.id,
                  menu_ids: [menu.id],
                  staff_ids: candidate_staff_ids,
                  overlap_restriction: overlap_restriction
                )

                if reserable_outcome.valid?
                  valid_menus << menu

                  # all menus got staffs to handle
                  if booking_option.menus.count == valid_menus.length
                    # Rails.logger.info("====#{date}===#{booking_start_at.to_s(:time)}~#{booking_end_at.to_s(:time)}========")
                    throw :next_working_date, date
                  end
                end
              end
            end

            booking_start_at = booking_start_at.advance(minutes: interval)
          end
        end

        # XXX: When date is not available to book, return nil, otherwise it returns booking_option instance by default
        nil
      end
    end
  end
end
