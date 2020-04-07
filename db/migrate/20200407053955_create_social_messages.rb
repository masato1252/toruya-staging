class CreateSocialMessages < ActiveRecord::Migration[5.2]
  def change
    create_table :social_messages do |t|
      t.integer :social_account_id, null: false
      t.integer :social_customer_id, null: false
      t.integer :staff_id
      t.text :raw_content

      t.timestamps
    end

    add_index :social_messages, [:social_account_id, :social_customer_id], name: :social_message_customer_index
  end
end
