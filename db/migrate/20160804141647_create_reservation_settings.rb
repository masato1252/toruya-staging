class CreateReservationSettings < ActiveRecord::Migration[5.0]
  def change
    create_table :reservation_settings do |t|
      t.integer :user_id
      t.string :name, :short_name, :day_type
      t.integer :day, :nth_of_week
      t.string :days_of_week, array: true, default: []
      t.datetime :start_time, :end_time


      t.timestamps
    end

    add_index :reservation_settings, [:user_id, :start_time, :end_time, :day_type, :days_of_week, :day, :nth_of_week], name: :reservation_setting_index
  end
end
