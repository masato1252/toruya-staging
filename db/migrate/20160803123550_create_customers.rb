class CreateCustomers < ActiveRecord::Migration[5.0]
  def change
    create_table :customers do |t|
      t.integer :user_id
      t.string :last_name
      t.string :first_name
      t.string :phonetic_last_name
      t.string :phonetic_first_name
      t.string :address
      t.string :google_account_token # use to keep the user's google account access_token to avoid user sync his/her two google accounts.
      t.string :google_contact_id
      t.string :google_contact_group_ids, array: true, default: []
      t.date :birthday

      t.timestamps
    end

    add_index :customers, [:user_id, :phonetic_last_name, :phonetic_first_name], name: "jp_name_index"
    add_index :customers, [:user_id, :google_contact_id]
  end
end
