class CreateSettingsMenus < ActiveRecord::Migration[5.0]
  def change
    create_table :menus do |t|
      t.integer :shop_id, null: false
      t.string :name, null: false
      t.string :shortname
      t.integer :minutes
      t.integer :min_staffs_number
      t.integer :max_seat_number

      t.timestamps
    end

    add_index :menus, :shop_id
  end
end
