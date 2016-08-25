class CreateCustomers < ActiveRecord::Migration[5.0]
  def change
    create_table :customers do |t|
      t.integer :shop_id
      t.string :last_name
      t.string :first_name
      t.string :jp_last_name
      t.string :jp_first_name
      t.string :state
      t.string :phone_number
      t.string :phone_type
      t.date :birthday

      t.timestamps
    end

    add_index :customers, [:jp_last_name, :jp_first_name], name: "jp_name_index"
  end
end
