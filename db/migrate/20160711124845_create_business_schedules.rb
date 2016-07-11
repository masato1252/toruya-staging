class CreateBusinessSchedules < ActiveRecord::Migration[5.0]
  def change
    create_table :business_schedules do |t|
      t.integer :shop_id
      t.integer :staff_id
      t.string :business_state
      t.datetime :start_time
      t.datetime :end_time
      t.integer :days_of_week

      t.timestamps
    end

    add_index :business_schedules, [:shop_id, :business_state, :days_of_week], name: :shop_day_of_week_index
  end
end
