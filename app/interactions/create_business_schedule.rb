class CreateBusinessSchedule < ActiveInteraction::Base
  set_callback :type_check, :before do
    attrs.merge!(staff_id: staff.id)  if staff
  end

  object :shop, class: Shop
  object :staff, class: Staff, default: nil
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
    if schedule.new_record? && attrs[:business_state] == "closed" &&
      attrs[:start_time].blank? && attrs[:end_time].blank? && attrs[:full_time].blank?
      return
    end

    if attrs[:full_time]
      schedule.update(attrs.except(:id, :business_state))

      shop.business_schedules.where(staff_id: staff.id, full_time: nil).destroy_all if staff
    else
      if schedule.update(attrs.except(:id)) && staff
        shop.business_schedules.where(staff_id: staff.id, full_time: true).destroy_all
      else
        errors.merge!(schedule.errors) if schedule.errors.present?
      end
    end
  end
end
