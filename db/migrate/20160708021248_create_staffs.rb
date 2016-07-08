class CreateStaffs < ActiveRecord::Migration[5.0]
  def change
    create_table :staffs do |t|
      t.integer :shop_id, null: false
      t.string :name, null: false
      t.string :shortname

      t.timestamps
    end

    add_index :staffs, :shop_id
  end
end
