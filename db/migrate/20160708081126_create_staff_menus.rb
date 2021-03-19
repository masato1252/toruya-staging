# frozen_string_literal: true

class CreateStaffMenus < ActiveRecord::Migration[5.0]
  def change
    create_table :staff_menus do |t|
      t.integer :staff_id, null: false
      t.integer :menu_id, null: false
      t.integer :max_customers

      t.timestamps
    end

    add_index :staff_menus, [:staff_id, :menu_id], unique: true
  end
end
