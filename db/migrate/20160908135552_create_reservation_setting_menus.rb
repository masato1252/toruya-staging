class CreateReservationSettingMenus < ActiveRecord::Migration[5.0]
  def change
    create_table :reservation_setting_menus do |t|
      t.integer :reservation_setting_id
      t.integer :menu_id

      t.timestamps
    end

    add_index :reservation_setting_menus, [:reservation_setting_id, :menu_id], name: :reservation_setting_menus_index
  end
end
