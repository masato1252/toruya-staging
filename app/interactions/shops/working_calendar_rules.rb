module Shops
  class WorkingCalendarRules < ActiveInteraction::Base
    object :shop
    object :date_range, class: Range

    def execute
      shop_closed_dates = shop.custom_schedules.for_shop.closed.
        where(start_time: date_range).
        select("start_time").
        order("start_time").
        map { |d| d.start_time.to_date }

      {
        full_time: true,
        shop_working_on_holiday: !!shop.holiday_working,
        shop_working_wdays: shop.business_schedules.for_shop.opened.map(&:day_of_week),
        holidays: Holidays.between(start_date, end_date).map { |holiday| holiday[:date] },
        off_dates: shop_closed_dates
      }
    end

    private

    def start_date
      date_range.first
    end

    def end_date
      date_range.last
    end
  end
end
