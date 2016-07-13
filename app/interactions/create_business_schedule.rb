class CreateBusinessSchedule < ActiveInteraction::Base
  object :shop, class: Shop
  hash :attrs do
    string :id
    integer :days_of_week
    string :business_state, default: "closed"
    string :start_time, default: nil
    string :end_time, default: nil
  end

  def execute
    schedule = shop.business_schedules.for_shop.find_or_initialize_by(id: attrs[:id])
    schedule.update(attrs.except(:id))
  end
end
