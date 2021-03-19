# frozen_string_literal: true

class BookingPageCacheJob < ApplicationJob
  queue_as :default

  def perform(booking_page)
    [Date.today, Date.today.next_month, Date.today.next_month.next_month].each do |date|
      month_dates = date.beginning_of_month.beginning_of_day..date.end_of_month.end_of_day

      special_dates = booking_page.booking_page_special_dates.where(start_at: month_dates).map do |special_date|
        {
          start_at_date_part: special_date.start_at_date,
          start_at_time_part: special_date.start_at_time,
          end_at_date_part:   special_date.end_at_date,
          end_at_time_part:   special_date.end_at_time
        }.to_json
      end

      outcome = Booking::Calendar.run(
        shop: booking_page.shop,
        booking_page: booking_page,
        date_range: month_dates,
        booking_option_ids: booking_page.booking_option_ids,
        special_dates: special_dates,
        special_date_type: booking_page.booking_page_special_dates.exists?,
        interval: booking_page.interval,
        overbooking_restriction: booking_page.overbooking_restriction
      )
    end
  end
end
