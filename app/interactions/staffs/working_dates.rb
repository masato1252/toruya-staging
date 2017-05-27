module Staffs
  class WorkingDates < ActiveInteraction::Base
    object :shop
    object :staff
    object :date_range, class: Range

    def execute
      is_staff_full_time = shop.business_schedules.full_time.where(staff_id: staff.id).exists?
      custom_schedules_scope = shop.custom_schedules.where(start_time: date_range).select("start_time").order("start_time")
      off_dates = working_dates = []

      # working dates
      if is_staff_full_time
        shop_working_wdays = shop.business_schedules.for_shop.opened.map(&:day_of_week)
      else
        staff_working_wdays = shop.business_schedules.opened.where(staff_id: staff.id).map(&:day_of_week)
        staff_on_dates = custom_schedules_scope.opened.where(staff_id: staff.id).map{|d| d.start_time.to_date }
        working_dates = staff_on_dates
      end

      # off dates
      # when date is a working day unless it's all day off
      shop_closed_dates = custom_schedules_scope.closed.for_shop.map{|d| d.start_time.to_date }
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

      off_dates << shop_closed_dates

      {
        full_time: is_staff_full_time,
        shop_working_on_holiday: shop.holiday_working,
        shop_working_wdays: shop_working_wdays,
        staff_working_wdays: staff_working_wdays,
        working_dates: working_dates.flatten,
        off_dates: off_dates.flatten,
        holidays: Holidays.between(date_range.first, date_range.last).map { |holiday| holiday[:date] }
      }
    end
  end
end
