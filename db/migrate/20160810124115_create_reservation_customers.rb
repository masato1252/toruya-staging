class CreateReservationCustomers < ActiveRecord::Migration[5.0]
  def change
    create_table :reservation_customers do |t|
      t.integer :reservation_id, null: false
      t.integer :customer_id, null: false

      t.timestamps
    end

    add_index :reservation_customers, [:reservation_id, :customer_id], unique: true
  end
end
