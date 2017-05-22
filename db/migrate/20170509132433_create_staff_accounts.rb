class CreateStaffAccounts < ActiveRecord::Migration[5.0]
  def change
    create_table :staff_accounts do |t|
      t.string :email, null: false
      t.references :user
      t.references :owner, null: false
      t.references :staff, null: false
      t.string :token
      t.integer :state, default: 0, null: false
      t.integer :level, default: 0, null: false
      t.timestamps
    end

    add_index :staff_accounts, [:owner_id, :email], name: :staff_account_email_index
    add_index :staff_accounts, [:owner_id, :user_id], name: :staff_account_index
    add_index :staff_accounts, [:token], name: :staff_account_token_index
  end
end
