class AddMissingIndex < ActiveRecord::Migration[5.0]
  def change
    add_index :business_schedules, [:staff_id, :business_state, :days_of_week], name: :business_schedules_index
    add_index :reservation_settings, [:menu_id, :start_time, :end_time, :day_type, :day_of_week, :day, :nth_of_week], name: :reservation_settings_index
    add_index :custom_schedules, [:staff_id, :start_time, :end_time], name: :custom_schedules_index
  end
end
