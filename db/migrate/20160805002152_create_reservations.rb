class CreateReservations < ActiveRecord::Migration[5.0]
  def change
    create_table :reservations do |t|
      t.integer :shop_id, null: false
      t.integer :menu_id, null: false
      t.datetime :start_time, null: false
      t.datetime :end_time, null: false
      t.text :memo

      t.timestamps
    end

    add_index :reservations, [:shop_id, :menu_id, :start_time, :end_time], name: :reservation_index
  end
end
