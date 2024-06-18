# frozen_string_literal: true

module Reservable
  class Time < ActiveInteraction::Base
    include SharedMethods

    object :shop
    date :date

    def execute
      # Custom -> Holiday -> Business

      # Custom
      if custom_close_schedule = shop.custom_schedules.for_shop.where(start_time: date.beginning_of_day..date.end_of_day).order("end_time").last
        schedule = business_schedules.last

        if schedule && schedule.end_time > custom_close_schedule.end_time
          return [custom_close_schedule.end_time..schedule.end_time]
        else
          errors.add(:date, :shop_closed)
        end
      end

      # Holiday
      # XXX: Japan dependency
      if date.holiday?(:jp)
        if shop.holiday_working && holiday_working_schedules.present?
          return holiday_working_schedules
        else
          errors.add(:date, :shop_closed)
        end
      end

      # normal business day
      business_working_schedules
    end

    private

    def business_schedules
      @business_schedules ||= {}
      @business_schedules[date.wday] ||= shop.business_schedules.for_shop.where(day_of_week: date.wday).order(:start_time).opened.all
    end

    def holiday_working_schedules
      shop.business_schedules.for_shop.opened.holiday_working.map do |schedule|
        schedule.start_time_on(date)..schedule.end_time_on(date)
      end
    end

    def business_working_schedules
      if business_schedules.present?
        business_schedules.map do |schedule|
          schedule.start_time_on(date)..schedule.end_time_on(date)
        end
      else
        errors.add(:date, :shop_closed)
      end
    end
  end
end
