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

    def execute
      rules = compose(Shops::WorkingCalendarRules, shop: shop, date_range: date_range)
      # Available booking dates

      if special_dates
        special_dates.map do |special_date|
          # {"start_at_date_part"=>"2019-05-06", "start_at_time_part"=>"01:00", "end_at_date_part"=>"2019-05-06", "end_at_time_part"=>"12:59"}
          JSON.parse(special_date)["start_at_date_part"]
        end
      else
        booking_options = shop.user.booking_options.where(id: booking_option_ids)
        booking_options = compose(BookingOptions::Prioritize, booking_options: booking_options)
      end

      compose(CalendarSchedules::Create, rules: rules, date_range: date_range)
    end

    private

    def start_date
    end

    def end_date
    end
  end
end
