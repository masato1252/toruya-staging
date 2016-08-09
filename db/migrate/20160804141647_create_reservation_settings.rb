class CreateReservationSettings < ActiveRecord::Migration[5.0]
  def change
    create_table :reservation_settings do |t|
      t.integer :menu_id
      t.string :name, :short_name, :reservation_type, :day_type, :time_type
      t.integer :day, :day_of_week, :nth_of_week
      t.datetime :start_time, :end_time


      t.timestamps
    end
  end
end
