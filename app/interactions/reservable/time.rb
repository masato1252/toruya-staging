module Reservable
  class Time < ActiveInteraction::Base
    include SharedMethods

    object :shop
    date :date

    def execute
      # Custom -> Holiday -> Business

      # Custom
      if custom_close_schedule = shop.custom_schedules.where(start_time: date.beginning_of_day..date.end_of_day).order("end_time").last
        schedule = business_schedule

        if schedule && schedule.end_time > custom_close_schedule.end_time
          return custom_close_schedule.end_time..schedule.end_time
        else
          return
        end
      end

      # Holiday
      if date.holiday?(:jp)
        if shop.holiday_working
          return business_working_schedule
        else
          return
        end
      end

      # normal bussiness day
      business_working_schedule
    end

    private

    def business_schedule
      @business_schedule ||= {}
      @business_schedule[date.wday] ||= shop.business_schedules.for_shop.where(day_of_week: date.wday).opened.first
    end

    def business_working_schedule
      if schedule = business_schedule
        schedule.start_time..schedule.end_time
      end
    end
  end
end
