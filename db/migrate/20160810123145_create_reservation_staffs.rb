class CreateReservationStaffs < ActiveRecord::Migration[5.0]
  def change
    create_table :reservation_staffs do |t|
      t.integer :reservation_id
      t.integer :staff_id

      t.timestamps
    end

    add_index :reservation_staffs, [:reservation_id, :staff_id], unique: true
  end
end
