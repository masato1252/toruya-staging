module CustomSchedules
  class Create < ActiveInteraction::Base
    object :shop, default: nil
    object :staff, default: nil
    hash :attrs, default: {} do
      string :id, default: nil
      string :shop_id, default: nil
      string :start_time_date_part, default: nil
      string :start_time_time_part, default: nil
      string :end_time_time_part, default: nil
      string :reason, default: nil
      string :reference_id, default: nil
      boolean :_destroy, default: false
      boolean :open, default: false
    end

    def execute
      owner = shop || staff

      schedule = owner.custom_schedules.find_or_initialize_by(id: attrs[:id])

      # Only the off schedule created in personal dashbaord would have reference_id
      if schedule.reference_id
        if attrs[:_destroy]
          if schedule.persisted?
            CustomSchedule.where(reference_id: schedule.reference_id).destroy_all
          end
        else
          CustomSchedule.where(reference_id: schedule.reference_id).each do |custom_schedule|
            custom_schedule.update(attrs.except(:id, :_destroy))
          end
        end
      else
        if attrs[:_destroy]
          schedule.destroy if schedule.persisted?
        else
          schedule.update(attrs.except(:id, :_destroy))
        end
      end
    end
  end
end
