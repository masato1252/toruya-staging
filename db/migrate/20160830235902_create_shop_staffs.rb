# frozen_string_literal: true

class CreateShopStaffs < ActiveRecord::Migration[5.0]
  def change
    create_table :shop_staffs do |t|
      t.integer :shop_id
      t.integer :staff_id

      t.timestamps
    end

    add_index :shop_staffs, [:shop_id, :staff_id], unique: true
  end
end
