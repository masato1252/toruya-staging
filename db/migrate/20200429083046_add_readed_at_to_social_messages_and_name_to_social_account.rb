class AddReadedAtToSocialMessagesAndNameToSocialAccount < ActiveRecord::Migration[5.2]
  def change
    add_column :social_messages, :readed_at, :datetime
    add_column :social_accounts, :label, :string
  end
end
