module Booking
  class Calendar < ActiveInteraction::Base
    include ::Booking::SharedMethods

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

          # XXX: Heroku keep meeting R14 & R15 memory errors, try does Parallel cause the problem
          if true || Rails.env.test?
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

            loop_for_reserable_spot(shop, booking_option, date, booking_start_at, booking_end_at, overlap_restriction) do
              throw :next_working_date, date
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
