module Booking
  class ValidateSpecialDates < ActiveInteraction::Base
    object :shop
    # special_dates
    # [
    # "{\"start_at_date_part\":\"2019-05-06\",\"start_at_time_part\":\"01:00\",\"end_at_date_part\":\"2019-05-06\",\"end_at_time_part\":\"12:59\"}",
    # "{\"start_at_date_part\":\"2019-05-23\",\"start_at_time_part\":\"01:00\",\"end_at_date_part\":\"2019-05-23\",\"end_at_time_part\":\"12:59\"}"
    # ]
    array :special_dates

    def execute
      dates = special_dates.map do |special_date|
        # {"start_at_date_part"=>"2019-05-06", "start_at_time_part"=>"01:00", "end_at_date_part"=>"2019-05-06", "end_at_time_part"=>"12:59"}
        Date.parse(JSON.parse(special_date)["start_at_date_part"])
      end.uniq

      invalid_special_dates = dates.find_all do |special_date|
        date_range = special_date..special_date

        rules = compose(Shops::WorkingCalendarRules, shop: shop, date_range: date_range)
        schedules = compose(CalendarSchedules::Create, rules: rules, date_range: date_range)

        schedules[:working_dates].length.zero?
      end.sort!

      if invalid_special_dates.present?
        errors.add(:special_dates, :on_unworking_dates, invalid_dates: invalid_special_dates.map { |date| I18n.l(date, format: :year_month_date) }.join(", "))
      end
    end
  end
end
