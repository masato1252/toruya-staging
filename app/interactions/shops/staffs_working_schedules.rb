# frozen_string_literal: true

module Shops
  class StaffsWorkingSchedules < ActiveInteraction::Base
    object :shop
    date :date

    def execute
      h = {}
      if full_working_time_range_array = compose(Reservable::Time, shop: shop, date: date)
        # Full time
        shop.business_schedules.for_staff.full_time.includes(:staff).each do |schedule|
          h[schedule.staff] = { time: full_working_time_range_array }
        end

        # weekly part time
        shop.business_schedules.for_staff.part_time.opened.where(day_of_week: date.wday).includes(:staff).each do |schedule|
          h[schedule.staff] = { time: [ schedule.start_time_on(date)..schedule.end_time_on(date) ] }
        end

        # custom open part time
        shop.custom_schedules.for_staff.opened.where("start_time >= ? and end_time <= ?", date.beginning_of_day, date.end_of_day).includes(:staff).each do |schedule|
          h[schedule.staff] = { time: [ schedule.start_time..schedule.end_time ] }
        end

        working_staffs = h.keys
        # custom leaving, if staff don't working on that date then we don't care about his/her OOO.
        working_staff_ids = working_staffs.map(&:id)
        active_staff_accounts = shop.user.owner_staff_accounts.active.where(staff_id: working_staff_ids).to_a

        # TODO: [Personal schedule legacy] Remove staff custom off schedule query when it indeed doesn't be used
        custom_schedules_scope = CustomSchedule.closed.where("start_time >= ? and end_time <= ?", date.beginning_of_day, date.end_of_day).includes(:staff)
        custom_schedules_scope.where(staff_id: working_staff_ids).or(
          custom_schedules_scope.where(user_id: active_staff_accounts.map(&:user_id))
        ).each do |schedule|

          schedule_staff = schedule.staff || active_staff_accounts.find { |staff_account| staff_account.user_id == schedule.user_id }.staff

          working_schedule_times = h[schedule_staff][:time]

          working_schedule_times.each do |working_schedule_time|
            if working_schedule_time && schedule.start_time > working_schedule_time.first
              # working time -> leaving time
              h[schedule_staff] = { time: working_schedule_time.first..schedule.start_time, reason: schedule.reason.presence || "臨時休暇" }
            elsif working_schedule_time && schedule.end_time < working_schedule_time.last
              # leaving time -> working time
              h[schedule_staff] = { time: schedule.end_time..working_schedule_time.last, reason: schedule.reason.presence || "臨時休暇" }
            else
              h[schedule_staff] = { time: nil, reason: schedule.reason.presence || "臨時休暇" }
            end
          end
        end

        h
      end
    end
  end
end
