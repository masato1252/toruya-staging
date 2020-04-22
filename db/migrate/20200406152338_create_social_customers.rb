class CreateSocialCustomers < ActiveRecord::Migration[5.2]
  def change
    create_table :social_customers do |t|
      t.references :user, null: false
      t.references :customer
      t.integer :social_account_id
      t.string :social_user_id, null: false
      t.string :social_user_name
      t.string :social_user_picture_url
      t.integer :conversation_state, default: 0

      t.timestamps
    end

    add_index :social_customers, [:user_id, :social_account_id, :social_user_id], unique: true, name: :social_customer_unique_index
  end
end
