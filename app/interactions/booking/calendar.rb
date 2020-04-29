module Booking
  class Calendar < ActiveInteraction::Base
    include ::Booking::SharedMethods

    object :shop
    object :booking_page
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
    boolean :special_date_type, default: false
    integer :interval, default: 30
    boolean :overbooking_restriction, default: true

    def execute
      rules = compose(::Shops::WorkingCalendarRules, shop: shop, date_range: date_range)
      schedules = compose(CalendarSchedules::Create, rules: rules, date_range: date_range)
      available_booking_dates = []

      booking_options = compose(
        BookingOptions::Prioritize,
        booking_options: shop.user.booking_options.where(id: booking_option_ids).includes(:menus)
      )

      if special_date_type || special_dates.present?
        # available_working_dates = special_dates.map do |special_date|
        #   # {"start_at_date_part"=>"2019-05-06", "start_at_time_part"=>"01:00", "end_at_date_part"=>"2019-05-06", "end_at_time_part"=>"12:59"}
        #   JSON.parse(special_date)["start_at_date_part"]
        # end.select { |date| Date.parse(date) >= booking_page.available_booking_start_date }

        available_booking_dates =
          # XXX: Heroku keep meeting R14 & R15 memory errors, Parallel cause the problem
          # if true || Rails.env.test?
            special_dates.map do |raw_special_date|
              json_parsed_date = JSON.parse(raw_special_date)
              special_date = Date.parse(json_parsed_date[START_AT_DATE_PART])
              next if special_date < booking_page.available_booking_start_date

              special_date_start_at = Time.zone.parse("#{json_parsed_date[START_AT_DATE_PART]}-#{json_parsed_date[START_AT_TIME_PART]}")
              special_date_end_at = Time.zone.parse("#{json_parsed_date[END_AT_DATE_PART]}-#{json_parsed_date[END_AT_TIME_PART]}")

              test_available_booking_date(booking_options, special_date, special_date_start_at, special_date_end_at)
            end.compact
          # else
          #   # XXX: Parallel doesn't work properly in test mode,
          #   # some data might be stay in transaction of test thread and would lost in test while using Parallel.
          #   Parallel.map(available_working_dates) do |date|
          #     test_available_booking_date(booking_options, date)
          #   end.compact
          # end
      else
        available_working_dates = schedules[:working_dates].map { |date| Date.parse(date) }
        available_working_dates = available_working_dates.select { |date| date >= booking_page.available_booking_start_date }

        available_booking_dates =
          # XXX: Heroku keep meeting R14 & R15 memory errors, Parallel cause the problem
          # if true || Rails.env.test?
            available_working_dates.map do |date|
              test_available_booking_date(booking_options, date)
            end.compact
          # else
          #   # XXX: Parallel doesn't work properly in test mode,
          #   # some data might be stay in transaction of test thread and would lost in test while using Parallel.
          #   Parallel.map(available_working_dates) do |date|
          #     test_available_booking_date(booking_options, date)
          #   end.compact
          # end
      end


      [
        schedules,
        available_booking_dates
      ]
    end

    private

    def test_available_booking_date(booking_options, date, booking_available_start_at = nil, booking_available_end_at = nil)
      time_range_outcome = Reservable::Time.run(shop: shop, date: date)
      return if time_range_outcome.invalid?

      time_range = time_range_outcome.result
      booking_available_end_at ||= shop_close_at = time_range.last

      catch :next_working_date do
        booking_options.each do |booking_option|
          # booking_option doesn't sell on that date
          if booking_option.start_time.to_date > date ||
              booking_option.end_at && booking_option.end_at.to_date < date
            next
          end

          booking_available_start_at ||= shop_open_at = time_range.first

          loop do
            booking_end_at = booking_available_start_at.advance(minutes: booking_option.minutes)

            if booking_end_at > booking_available_end_at
              break
            end

            loop_for_reserable_spot(shop: shop, booking_page: booking_page, booking_option: booking_option, date: date, booking_start_at: booking_available_start_at, overbooking_restriction: overbooking_restriction) do
              throw :next_working_date, date.to_s
            end

            booking_available_start_at = booking_available_start_at.advance(minutes: interval)
          end
        end

        # XXX: When date is not available to book, return nil, otherwise it returns booking_option instance by default
        nil
      end
    end
  end
end
