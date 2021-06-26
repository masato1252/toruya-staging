class AddScheduleAtAndSendAtToSocialUserMessages < ActiveRecord::Migration[5.2]
  def change
    add_column :social_user_messages, :schedule_at, :datetime
    add_column :social_user_messages, :sent_at, :datetime

    SocialUserMessage.update_all("sent_at=created_at")
  end
end
