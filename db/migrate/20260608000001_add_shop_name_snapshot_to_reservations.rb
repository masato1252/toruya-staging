# frozen_string_literal: true

class AddShopNameSnapshotToReservations < ActiveRecord::Migration[7.0]
  def up
    add_column :reservations, :shop_name_snapshot, :string

    execute <<~SQL.squish
      UPDATE reservations
      SET shop_name_snapshot = shops.name
      FROM shops
      WHERE reservations.shop_id = shops.id
        AND reservations.shop_name_snapshot IS NULL
    SQL
  end

  def down
    remove_column :reservations, :shop_name_snapshot
  end
end
