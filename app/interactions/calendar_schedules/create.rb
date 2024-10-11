# frozen_string_literal: true

module CalendarSchedules
  class Create < ActiveInteraction::Base
    # full_time: is_staff_full_time,
    # shop_working_on_holiday: shop_calendar_rules[:shop_working_on_holiday],
    # shop_working_wdays: shop_calendar_rules[:shop_working_wdays] || [],
    # holidays: shop_calendar_rules[:holidays],
    # off_dates: off_dates.flatten, # for staff and shop
    # staff_working_wdays: staff_working_wdays || [],
    # working_dates: working_dates.flatten # for staff
    hash :rules, strip: false
    object :date_range, class: Range

    def execute
      holidays = []
      working_dates = []

      start_date = date_range.first.to_date
      end_date = date_range.last.to_date
      (start_date..end_date).each do |date|
        if is_working_date?(date)
          working_dates << date.to_s
        end

        if is_holiday_date?(date)
          holidays << date.to_s
        end
      end

      {
        working_dates: working_dates.uniq,
        holiday_dates: holidays
      }
    end

    private

    def is_working_date?(date)
      if (is_holiday_date?(date) && !rules[:shop_working_on_holiday]) || rules[:off_dates].include?(date)
        return false
      end

      if rules[:full_time]
        rules[:shop_working_wdays].include?(date.wday) || (is_holiday_date?(date) && rules[:shop_working_on_holiday])
      else
        rules[:staff_working_wdays].include?(date.wday) || rules[:working_dates].include?(date)
      end
    end

    def is_holiday_date?(date)
      rules[:holidays].include?(date)
    end
  end
end
