module CustomSchedules
  class PersonalCreate < ActiveInteraction::Base
    object :user
    hash :attrs, default: {} do
      string :shop_id, default: nil
      string :start_time_date_part, default: nil
      string :start_time_time_part, default: nil
      string :end_time_time_part, default: nil
      string :reason, default: nil
      boolean :open, default: false
    end

    def execute
      schedule = user.custom_schedules.create(attrs)

      errors.merge!(schedule.errors) if schedule.new_record?

      schedule
    end
  end
end
