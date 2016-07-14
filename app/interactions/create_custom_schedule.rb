class CreateCustomSchedule < ActiveInteraction::Base
  object :shop, class: Shop
  hash :attrs do
    string :id, default: nil
    string :start_time_date_part, default: nil
    string :start_time_time_part, default: nil
    string :end_time, default: nil
    string :reason, default: nil
    boolean :_destroy, default: false
  end

  def execute
    schedule = shop.custom_schedules.for_shop.find_or_initialize_by(id: attrs[:id])
    if attrs[:_destroy]
      schedule.destroy if schedule.persisted?
    else
      schedule.update(attrs.except(:id, :_destroy))
    end
  end
end
