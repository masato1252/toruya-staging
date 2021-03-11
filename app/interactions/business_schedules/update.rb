# frozen_string_literal: true

module BusinessSchedules
  class Update < ActiveInteraction::Base
    object :shop
    hash :attrs do
      string :id
      string :business_state
      string :start_time, default: nil
      string :end_time, default: nil
    end

    def execute
      schedule = shop.business_schedules.find(attrs[:id])

      schedule.update(attrs.except(:id))

      errors.merge!(schedule.errors) if schedule.errors.present?
      schedule
    end
  end
end
