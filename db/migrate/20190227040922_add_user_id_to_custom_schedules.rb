class AddUserIdToCustomSchedules < ActiveRecord::Migration[5.1]
  def change
    remove_index :custom_schedules, name: :shop_custom_schedules_index
    remove_index :custom_schedules, name: :staff_custom_schedules_index
    remove_index :custom_schedules, name: :index_custom_schedules_on_staff_id_and_open

    add_column :custom_schedules, :user_id, :integer
    add_index :custom_schedules, [:user_id, :open, :start_time, :end_time], name: "personal_schedule_index"
    add_index :custom_schedules, [:shop_id, :open, :start_time, :end_time], name: "shop_custom_schedules_index"
    add_index :custom_schedules, [:staff_id, :open, :start_time, :end_time], name: "staff_custom_schedules_index"
  end
end
