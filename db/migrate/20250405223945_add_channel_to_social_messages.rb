class AddChannelToSocialMessages < ActiveRecord::Migration[7.0]
  def change
    add_column :social_messages, :channel, :string
    add_column :social_messages, :customer_id, :integer
    add_index :social_messages, [:customer_id, :channel]
    add_column :social_messages, :user_id, :integer
    add_index :social_messages, [:user_id, :channel]
    # social_account and social_customer are nullable
    change_column_null :social_messages, :social_account_id, true
    change_column_null :social_messages, :social_customer_id, true

    SocialMessage.update_all(channel: "line")
    SocialCustomer.find_each do |social_customer|
      SocialMessage.where(social_account_id: social_customer.social_account_id, social_customer_id: social_customer.id).update_all(
        user_id: social_customer.user_id || social_customer.social_account&.user_id, customer_id: social_customer.customer_id
      )
    end
  end
end
