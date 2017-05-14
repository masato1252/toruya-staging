class CreateStaffAccounts < ActiveRecord::Migration[5.0]
  def change
    create_table :staff_accounts do |t|
      t.string :email, null: false
      t.references :user
      t.references :owner, null: false
      t.references :staff, null: false
      t.integer :state, default: 0, null: false
      t.integer :level, default: 0, null: false
      t.timestamps
    end

    add_index :staff_accounts, [:owner_id, :state, :email], name: :staff_account_email_index
    add_index :staff_accounts, [:owner_id, :state, :user_id], name: :staff_account_index
  end
end
