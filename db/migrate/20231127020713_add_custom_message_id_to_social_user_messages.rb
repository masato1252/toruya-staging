class AddCustomMessageIdToSocialUserMessages < ActiveRecord::Migration[7.0]
  def change
    add_column :social_user_messages, :custom_message_id, :integer
    add_index :social_user_messages, [:social_user_id, :custom_message_id], name: :custom_message_social_user_messages_index
  end
end
