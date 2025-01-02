# frozen_string_literal: true

module Booking
  class Cache < ActiveInteraction::Base
    object :booking_page
    object :date

    def execute
      date_range = date.beginning_of_day..date.tomorrow.end_of_day
      special_dates = booking_page.booking_page_special_dates.where(start_at: date_range).map do |special_date|
        {
          start_at_date_part: special_date.start_at_date,
          start_at_time_part: special_date.start_at_time,
          end_at_date_part:   special_date.end_at_date,
          end_at_time_part:   special_date.end_at_time
        }.to_json
      end

      staff_ids = [booking_page.user.current_staff.id]
      booking_page.booking_option_ids.each do |booking_option_id|
        outcome = Booking::CalendarForTimeslot.run(
          shop: booking_page.shop,
          booking_page: booking_page,
          date_range: date_range,
          booking_option_ids: [booking_option_id],
          staff_ids: staff_ids,
          special_dates: special_dates,
          special_date_type: booking_page.booking_page_special_dates.exists?,
          interval: booking_page.interval,
          overbooking_restriction: booking_page.overbooking_restriction,
          force_update_cache: true
        )

        time_outcome = Reservable::Time.run(shop: booking_page.shop, booking_page: booking_page, date: date)
        booking_dates =
          if time_outcome.valid?
            time_outcome.result.map do |working_time|
              work_start_at = working_time.first
              work_end_at = working_time.last

              {
                start_at_date_part: work_start_at.to_date.to_fs,
                start_at_time_part: I18n.l(work_start_at, format: :hour_minute),
                end_at_date_part:   work_end_at.to_date.to_fs,
                end_at_time_part:   I18n.l(work_end_at, format: :hour_minute)
              }.to_json
            end
          else
            []
          end

        outcome = Booking::AvailableBookingTimesForTimeslot.run(
          shop: booking_page.shop,
          booking_page: booking_page,
          special_dates: booking_dates,
          booking_option_ids: [booking_option_id],
          staff_ids: staff_ids,
          interval: booking_page.interval,
          overbooking_restriction: booking_page.overbooking_restriction,
          force_update_cache: true
        )
      end
    end
  end
end
