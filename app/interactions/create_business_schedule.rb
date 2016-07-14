class CreateBusinessSchedule < ActiveInteraction::Base
  object :shop, class: Shop
  object :staff, class: Staff, default: nil
  hash :attrs do
    string :id, default: nil
    integer :days_of_week
    string :business_state, default: "closed"
    string :start_time, default: nil
    string :end_time, default: nil
  end

  def execute
    schedule = shop.business_schedules.find_or_initialize_by(id: attrs[:id])
    if schedule.new_record? && attrs[:business_state] == "closed" && attrs[:start_time].blank? && attrs[:end_time].blank?
      return
    end

    unless schedule.update(attrs.merge(staff_id: staff.try(:id)).except(:id))
      errors.merge!(schedule.errors)
    end
  end
end
