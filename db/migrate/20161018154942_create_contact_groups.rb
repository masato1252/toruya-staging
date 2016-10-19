class CreateContactGroups < ActiveRecord::Migration[5.0]
  def change
    create_table :contact_groups do |t|
      t.references :user, null: false
      t.string :google_uid, null: false
      t.string :google_group_id, null: false
      t.string :name, null: false
      t.timestamps
    end

    add_index :contact_groups, [:user_id, :google_uid, :google_group_id], name: "contact_groups_google_index", unique: true
  end
end
