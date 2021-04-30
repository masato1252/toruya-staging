class AddRequireColumnForSocialMessages < ActiveRecord::Migration[5.2]
  def change
    add_column :social_messages, :schedule_at, :datetime
    add_column :social_messages, :sent_at, :datetime

    SocialMessage.update_all("sent_at=created_at")
  end
end
