class CreateBusinessSchedules < ActiveRecord::Migration[5.0]
  def change
    create_table :business_schedules do |t|
      t.integer :shop_id
      t.integer :staff_id
      t.string :business_state
      t.integer :day_of_week
      t.datetime :start_time
      t.datetime :end_time

      t.timestamps
    end

    add_index :business_schedules, [:shop_id, :business_state, :day_of_week, :start_time, :end_time], name: :shop_day_of_week_index
    add_index :business_schedules, [:staff_id, :business_state, :day_of_week, :start_time, :end_time], name: :staff_day_of_week_index
  end
end
