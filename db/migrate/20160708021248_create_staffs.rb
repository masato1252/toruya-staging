class CreateStaffs < ActiveRecord::Migration[5.0]
  def change
    create_table :staffs do |t|
      t.integer :user_id, null: false
      t.string :last_name
      t.string :first_name
      t.string :phonetic_last_name
      t.string :phonetic_first_name

      t.timestamps
    end

    add_index :staffs, :user_id
  end
end
