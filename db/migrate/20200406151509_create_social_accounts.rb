# frozen_string_literal: true

class CreateSocialAccounts < ActiveRecord::Migration[5.2]
  def change
    create_table :social_accounts do |t|
      t.integer :user_id, null: false
      t.string :channel_id, null: false
      t.string :channel_token, null: false
      t.string :channel_secret, null: false

      t.timestamps
    end

    add_index :social_accounts, [:user_id, :channel_id], unique: true
  end
end
