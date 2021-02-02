# frozen_string_literal: true

module BusinessSchedules
  class Create < ActiveInteraction::Base
    set_callback :type_check, :before do
      attrs.merge!(staff_id: staff.id)  if staff
    end

    object :shop
    object :staff, default: nil
    hash :attrs do
      string :id, default: nil
      boolean :full_time, default: nil
      integer :day_of_week, default: nil
      string :business_state, default: "closed"
      string :start_time, default: nil
      string :end_time, default: nil
      integer :staff_id, default: nil
    end

    def execute
      schedule = shop.business_schedules.find_or_initialize_by(id: attrs[:id])

      if attrs[:full_time]
        schedule.update(attrs.except(:id, :business_state))

        shop.business_schedules.where(staff_id: staff.id, full_time: nil).destroy_all if staff
      else
        schedule.update(attrs.except(:id)) if attrs[:day_of_week] # weekly schedule
        shop.business_schedules.where(staff_id: staff.id, full_time: true).destroy_all if staff

        errors.merge!(schedule.errors) if schedule.errors.present?
      end
    end
  end
end
