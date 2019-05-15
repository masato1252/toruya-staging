module Booking
  class ValidateSpecialDates < ActiveInteraction::Base
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

    def execute
      invalid_special_dates = []
      not_enough_time_special_dates = []

      longest_option = shop.user.booking_options.where(id: booking_option_ids).sort_by { |option| option.minutes }.last

      # case 1: the reservation starts at 9:00 AM, it'll be 70(9:00 to 10:10) => OK
      # case 2: the reservation starts at 9:01 AM, it'll be 80(9:01 to 11:01) => OK
      # case 3: the reservation starts at 3:40 PM, it will be 80 (3:40 to 5:00) => OK
      # case 4: the reservation starts at 3:41 PM, it will be 79 (3:41 to 5:00) => OK
      # case 6: the reservation starts at 3:49 PM, it will be 71 (3:49 to 5:00) => OK
      # case 7: the reservation starts at 3:50 PM, it will be 70 (3:50 to 5:00) => OK
      # case 8: the reservation starts at 3:51 PM, it will be 70 (3:51 to 5:01) => Failed
      special_dates.each do |raw_special_date|
        json_parsed_date = JSON.parse(raw_special_date)
        special_date = Date.parse(json_parsed_date["start_at_date_part"])
        time_outcome = Reservable::Time.run(shop: shop, date: special_date)

        if time_outcome.valid?
          shop_start_at = time_outcome.result.first
          shop_closed_at = time_outcome.result.last
          special_date_start_at = Time.zone.parse("#{json_parsed_date["start_at_date_part"]}-#{json_parsed_date["start_at_time_part"]}")
          special_date_end_at = Time.zone.parse("#{json_parsed_date["end_at_date_part"]}-#{json_parsed_date["end_at_time_part"]}")
          special_date_time_length = special_date_end_at - special_date_start_at
          basic_required_minutes = longest_option.minutes + longest_option.interval
          long_required_minutes = longest_option.minutes + longest_option.interval * 2
          special_time_range = "#{I18n.l(special_date_start_at)} ~ #{I18n.l(special_date_end_at, format: :hour_minute)}"

          if special_date_start_at < shop_start_at ||
              special_date_end_at > shop_closed_at ||
              special_date_start_at > special_date_end_at
            invalid_special_dates << special_date
          elsif special_date_start_at.advance(minutes: basic_required_minutes) > shop_closed_at
            not_enough_time_special_dates << {
              time_range: special_time_range,
              required_time: basic_required_minutes
            }
          elsif special_date_start_at == shop_start_at
            if special_date_time_length < basic_required_minutes.minutes
              not_enough_time_special_dates << {
                time_range: special_time_range,
                required_time: basic_required_minutes
              }
            end
          elsif special_date_start_at.advance(minutes: long_required_minutes) > shop_closed_at
            # near shop close case
            required_time_length = shop_closed_at - special_date_start_at

            if special_date_time_length < required_time_length
              not_enough_time_special_dates << {
                time_range: special_time_range,
                required_time: required_time_length / 3_600
              }
            end
          else
            if special_date_time_length < long_required_minutes.minutes
              not_enough_time_special_dates << {
                time_range: special_time_range,
                required_time: long_required_minutes
              }
            end
          end
        else
          invalid_special_dates << special_date
        end
      end

      if invalid_special_dates.present?
        errors.add(:special_dates, :on_unworking_dates, invalid_dates: invalid_special_dates.map { |date| I18n.l(date, format: :year_month_date) }.join(", "))
      end

      if not_enough_time_special_dates.present?
        not_enough_time_dates = not_enough_time_special_dates.map do |not_enough_time_special_date|
          "#{not_enough_time_special_date[:time_range]} #{not_enough_time_special_date[:required_time]}"
        end.join(", ")
        errors.add(:special_dates, :not_enough_time_dates, not_enough_time_dates: not_enough_time_dates)
      end
    end
  end
end
