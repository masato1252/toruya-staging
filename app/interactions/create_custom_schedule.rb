class CreateCustomSchedule < ActiveInteraction::Base
  object :shop, default: nil
  object :staff, default: nil
  hash :attrs, default: {} do
    string :id, default: nil
    string :start_time_date_part, default: nil
    string :start_time_time_part, default: nil
    string :end_time_time_part, default: nil
    string :reason, default: nil
    boolean :_destroy, default: false
    boolean :open, default: false
  end

  def execute
    owner = shop || staff

    schedule = owner.custom_schedules.find_or_initialize_by(id: attrs[:id])
    if attrs[:_destroy]
      schedule.destroy if schedule.persisted?
    else
      schedule.update(attrs.except(:id, :_destroy))
    end
  end
end
