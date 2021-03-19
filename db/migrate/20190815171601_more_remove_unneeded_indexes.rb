# frozen_string_literal: true

class MoreRemoveUnneededIndexes < ActiveRecord::Migration[5.2]
  def change
    remove_index :reservation_menus, name: "index_reservation_menus_on_reservation_id"
  end
end
