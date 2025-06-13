class CreateMenuEquipments < ActiveRecord::Migration[7.0]
  def change
    create_table :menu_equipments do |t|
      t.references :menu, null: false
      t.references :equipment, null: false
      t.integer :required_quantity, default: 1, null: false

      t.timestamps
    end

    add_index :menu_equipments, [:menu_id, :equipment_id], unique: true
  end
end
