class CreateProfiles < ActiveRecord::Migration[5.0]
  def change
    create_table :profiles do |t|
      t.belongs_to :user, foreign_key: true
      t.string :first_name
      t.string :last_name
      t.string :phonetic_first_name
      t.string :phonetic_last_name
      t.string :company_name
      t.string :zip_code
      t.string :address
      t.string :phone_number
      t.string :website

      t.timestamps
    end
  end
end
