class AddAiUidToSocialUserMessages < ActiveRecord::Migration[7.0]
  def change
    add_column :social_user_messages, :ai_uid, :string
    add_index :social_user_messages, [:social_user_id, :ai_uid]
  end
end
