class CreateStaffAccounts < ActiveRecord::Migration[5.0]
  def change
    create_table :staff_accounts do |t|
      t.string :email, null: false
      t.references :user
      t.references :owner, null: false
      t.references :staff, null: false
      t.integer :state, default: 0, null: false
      t.boolean :active_uniqueness, default: false, null: false
      t.timestamps
    end

    add_index :staff_accounts, [:owner_id, :email, :active_uniqueness], name: :staff_account_email_index
    add_index :staff_accounts, [:owner_id, :user_id, :active_uniqueness], name: :staff_account_index
  end
end
