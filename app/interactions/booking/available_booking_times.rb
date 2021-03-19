# frozen_string_literal: true

module Booking
  class AvailableBookingTimes < ActiveInteraction::Base
    include ::Booking::SharedMethods

    object :shop
    # booking_option_ids
    # ["1"]
    object :booking_page
    array :booking_option_ids
    # special_dates
    # [
    # "{\"start_at_date_part\":\"2019-05-06\",\"start_at_time_part\":\"01:00\",\"end_at_date_part\":\"2019-05-06\",\"end_at_time_part\":\"12:59\"}",
    # "{\"start_at_date_part\":\"2019-05-23\",\"start_at_time_part\":\"01:00\",\"end_at_date_part\":\"2019-05-23\",\"end_at_time_part\":\"12:59\"}"
    # ]
    array :special_dates
    integer :interval
    boolean :overbooking_restriction, default: true
    integer :limit, default: nil

    def execute
      available_booking_time_mapping = {}

      catch :enough_booking_time do
        special_dates.each do |raw_special_date|
          catch :next_working_date do
            json_parsed_date = JSON.parse(raw_special_date)
            special_date = Date.parse(json_parsed_date[START_AT_DATE_PART])

            special_date_start_at = Time.zone.parse("#{json_parsed_date[START_AT_DATE_PART]}-#{json_parsed_date[START_AT_TIME_PART]}")
            special_date_end_at = Time.zone.parse("#{json_parsed_date[END_AT_DATE_PART]}-#{json_parsed_date[END_AT_TIME_PART]}")

            shop.user.booking_options.where(id: booking_option_ids).includes(:menus).order("booking_options.id").each do |booking_option|
              available_booking_times = []
              booking_start_at = special_date_start_at

              loop do
                booking_end_at = booking_start_at.advance(minutes: booking_option.minutes)

                if booking_end_at > special_date_end_at
                  break
                end

                loop_for_reserable_spot(shop: shop, booking_page: booking_page, booking_option: booking_option, date: booking_start_at.to_date, booking_start_at: booking_start_at, overbooking_restriction: overbooking_restriction) do
                  available_booking_times << booking_start_at

                  available_booking_time_mapping[booking_start_at] ||= []
                  available_booking_time_mapping[booking_start_at] << booking_option.id

                  throw :enough_booking_time if limit && available_booking_times.length >= limit
                end

                booking_start_at = booking_start_at.advance(minutes: interval)
              end
            end
          end
        end
      end

      available_booking_time_mapping
    end
  end
end
