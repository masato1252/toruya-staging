module Shops
  class StaffsWorkingSchedules < ActiveInteraction::Base
    object :shop
    date :date

    def execute
      h = {}
      if full_working_time_range = compose(Reservable::Time, shop: shop, date: date)
        # Full time
        shop.business_schedules.for_staff.full_time.includes(:staff).each do |schedule|
          h[schedule.staff] = { time: full_working_time_range }
        end

        # weekly part time
        shop.business_schedules.for_staff.part_time.opened.where(day_of_week: date.wday).includes(:staff).each do |schedule|
          h[schedule.staff] = { time: schedule.start_time..schedule.end_time }
        end

        # custom open part time
        shop.custom_schedules.for_staff.opened.where("start_time >= ? and end_time <= ?", date.beginning_of_day, date.end_of_day).includes(:staff).each do |schedule|
          h[schedule.staff] = { time: schedule.start_time..schedule.end_time }
        end

        working_staffs = h.keys
        # custom leaving, if staff don't working on that date then we don't care about his/her OOO.
        CustomSchedule.where(staff_id: working_staffs.map(&:id)).closed.where("start_time >= ? and end_time <= ?", date.beginning_of_day, date.end_of_day).includes(:staff).each do |schedule|
          if schedule.start_time > h[schedule.staff][:time].first
            # working time -> leaving time
            h[schedule.staff] = { time: h[schedule.staff][:time].first..schedule.start_time, reason: schedule.reason.presence || "臨時休暇" }
          elsif schedule.end_time < h[schedule.staff][:time].last
            # leaving time -> working time
            h[schedule.staff] = { time: schedule.end_time..h[schedule.staff][:time].last, reason: schedule.reason.presence || "臨時休暇" }
          else
            h[schedule.staff] = { time: nil, reason: schedule.reason.presence || "臨時休暇" }
          end
        end

        h
      end
    end
  end
end
