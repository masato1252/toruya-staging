# frozen_string_literal: true

module Staffs
  class WorkingDateRules < ActiveInteraction::Base
    object :shop
    object :staff
    object :date_range, class: Range

    def execute
      staff_id = staff.id

      is_staff_full_time = shop.business_schedules.full_time.where(staff_id: staff_id).exists?
      off_dates = working_dates = []
      shop_calendar_rules = compose(Shops::WorkingCalendarRules, shop: shop, date_range: date_range)

      # working dates
      unless is_staff_full_time
        staff_working_wdays = shop.business_schedules.opened.where(staff_id: staff_id).pluck(:day_of_week)
        working_dates = shop.custom_schedules.opened.where(staff_id: staff_id, start_time: date_range).
          select("start_time").
          order("start_time").
          pluck(:start_time).
          map { |start_time| start_time.to_date }
      end

      # off dates
      # when date is a working day unless it's all day off
      staff_off_date_candidates = staff.custom_schedules.closed.where(start_time: date_range).select("start_time").order("start_time").map{|d| d.start_time.to_date }

      staff_off_date_candidates.each do |suspicious_date|
        outcome = Shops::StaffsWorkingSchedules.run(shop: shop, date: suspicious_date)

        if outcome.valid?
          working_schedule_of_staffs = outcome.result

          if working_schedule_of_staffs && working_schedule_of_staffs[staff] && working_schedule_of_staffs[staff][:time].nil?
            off_dates << suspicious_date
          end
        end
      end

      off_dates << shop_calendar_rules[:off_dates]

      {
        full_time: is_staff_full_time,
        shop_working_on_holiday: shop_calendar_rules[:shop_working_on_holiday],
        shop_working_wdays: shop_calendar_rules[:shop_working_wdays] || [],
        holidays: shop_calendar_rules[:holidays],
        off_dates: off_dates.flatten, # for staff and shop
        staff_working_wdays: staff_working_wdays || [],
        working_dates: working_dates.flatten # for staff
      }
    end
  end
end
