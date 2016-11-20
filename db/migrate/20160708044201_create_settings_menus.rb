class CreateSettingsMenus < ActiveRecord::Migration[5.0]
  def change
    create_table :menus do |t|
      t.integer :user_id, null: false
      t.string :name, null: false
      t.string :short_name
      t.integer :minutes
      t.integer :interval
      t.integer :min_staffs_number
      t.integer :max_seat_number

      t.timestamps
    end

    add_index :menus, :user_id
  end
end
