class AddActiveUniquenessToStaffAccounts < ActiveRecord::Migration[5.1]
  def change
    add_column :staff_accounts, :active_uniqueness, :boolean, null: true
    add_index :staff_accounts, [:owner_id, :user_id, :active_uniqueness], name: :unique_staff_account_index, unique: true

    StaffAccount.where(state: :active).update_all(active_uniqueness: true)
  end
end
