# frozen_string_literal: true

class AddDeletedAtAndIndexToReservations < ActiveRecord::Migration[5.1]
  def change
    add_column :reservations, :deleted_at, :datetime
    add_index :menus, [:user_id, :deleted_at]
    add_index :shops, [:user_id, :deleted_at]
    add_index :staffs, [:user_id, :deleted_at]
    add_index :reservations, [:shop_id, :deleted_at]
  end
end
