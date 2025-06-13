class CreateEquipments < ActiveRecord::Migration[7.0]
  def change
    create_table :equipments do |t|
      t.string :name, null: false
      t.integer :quantity, default: 1, null: false
      t.references :shop, null: false
      t.datetime :deleted_at

      t.timestamps
    end

    add_index :equipments, [:shop_id, :deleted_at]
    add_index :equipments, :name
  end
end
