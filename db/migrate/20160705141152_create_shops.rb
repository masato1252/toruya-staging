class CreateShops < ActiveRecord::Migration[5.0]
  def change
    create_table :shops do |t|
      t.references :user
      t.string :name, null: false
      t.string :shortname, null: false
      t.string :zip_code, null: false
      t.string :phone_number, null: false
      t.string :email, null: false
      t.string :address, null: false
      t.string :website
      t.boolean :holiday_working
      t.timestamps
    end
  end
end
