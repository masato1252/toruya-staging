class CreateConsultantAccounts < ActiveRecord::Migration[7.0]
  def change
    create_table :consultant_accounts do |t|
      t.references :consultant_user, null: false
      t.string :phone_number, null: false
      t.string :token, null: false
      t.integer :state, default: 0, null: false

      t.timestamps
    end
    add_index :consultant_accounts, [:token], name: :consultant_account_token_index, unique: true
    add_index :consultant_accounts, [:consultant_user_id, :phone_number], name: :consultant_account_phone_index, unique: true
  end
end
