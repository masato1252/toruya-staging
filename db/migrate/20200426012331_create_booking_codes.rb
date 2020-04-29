class CreateBookingCodes < ActiveRecord::Migration[5.2]
  def change
    create_table :booking_codes do |t|
      t.string :uuid
      t.string :code
      t.integer :booking_page_id
      t.integer :customer_id
      t.integer :reservation_id

      t.timestamps
    end

    add_index :booking_codes, [:booking_page_id, :uuid, :code], unique: true
  end
end
