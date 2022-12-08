class AddSlackMessageIdToSocialUserMessages < ActiveRecord::Migration[6.0]
  def change
    add_column :social_user_messages, :slack_message_id, :string
  end
end
