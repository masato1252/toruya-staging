# frozen_string_literal: true

class CreateShopMenus < ActiveRecord::Migration[5.0]
  def change
    create_table :shop_menus do |t|
      t.integer :shop_id
      t.integer :menu_id

      t.timestamps
    end

    add_index :shop_menus, [:shop_id, :menu_id], unique: true
  end
end
