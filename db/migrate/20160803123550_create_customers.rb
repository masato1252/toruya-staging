class CreateCustomers < ActiveRecord::Migration[5.0]
  def change
    create_table :customers do |t|
      t.integer :shop_id
      t.string :last_name
      t.string :first_name
      t.string :state

      t.timestamps
    end
  end
end
