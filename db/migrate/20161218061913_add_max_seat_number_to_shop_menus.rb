# frozen_string_literal: true

class AddMaxSeatNumberToShopMenus < ActiveRecord::Migration[5.0]
  def up
    add_column :shop_menus, :max_seat_number, :integer, default: nil
    Menu.all.each do |menu|
      menu.shop_menus.update_all(max_seat_number: menu.max_seat_number)
    end

    remove_column :menus, :max_seat_number
  end

  def down
    add_column :menus, :max_seat_number, :integer, default: nil
    ShopMenu.all.each do |shop_menu|
      shop_menu.menu.update(max_seat_number: shop_menu.max_seat_number)
    end

    remove_column :shop_menus, :max_seat_number
  end
end
