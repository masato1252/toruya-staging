class CreateShops < ActiveRecord::Migration[5.0]
  def change
    create_table :shops do |t|
      t.references :user
      t.string :name, :shortname, :zip_code, :phone_number, :email, :website, :address
      t.timestamps
    end
  end
end
