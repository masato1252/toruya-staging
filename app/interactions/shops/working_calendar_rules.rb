# frozen_string_literal: true

module Shops
  class WorkingCalendarRules < ActiveInteraction::Base
    object :shop
    object :booking_page, default: nil
    object :date_range, class: Range

    def execute
      shop_closed_dates = shop.custom_schedules.for_shop.closed.
        where(start_time: date_range).
        select("start_time").
        order("start_time").
        pluck(:start_time).
        map { |start_time| start_time.to_date }

      {
        full_time: true,
        shop_working_on_holiday: !!shop.holiday_working,
        shop_working_wdays: booking_page&.business_schedules&.exists? ? booking_page.business_schedules.pluck(:day_of_week).uniq : shop.business_schedules.for_shop.opened.pluck(:day_of_week).uniq,
        holidays: holidays,
        off_dates: shop_closed_dates,
        holiday_working_option: shop.holiday_working_option
      }
    end

    private

    def start_date
      date_range.first
    end

    def end_date
      date_range.last
    end

    def holidays
      if I18n.locale == :tw
        TW_HOLIDAYS.select { |date| date.between?(start_date, end_date) }
      else
        Holidays.between(start_date, end_date, :jp).map { |holiday| holiday[:date] }
      end
    end
  end
end
