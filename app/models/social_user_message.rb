# frozen_string_literal: true
# == Schema Information
#
# Table name: social_user_messages
#
#  id             :bigint           not null, primary key
#  message_type   :integer
#  raw_content    :text
#  readed_at      :datetime
#  schedule_at    :datetime
#  sent_at        :datetime
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  admin_user_id  :integer
#  social_user_id :integer          not null
#
# Indexes
#
#  social_user_message_index  (social_user_id)
#

class SocialUserMessage < ApplicationRecord
  include SayHi
  hi_channel_name "toruya_users_support"

  belongs_to :social_user, touch: true
  has_one_attached :image

  scope :unread, -> { where(readed_at: nil) }

  enum message_type: {
    bot: 0,
    admin: 1,
    user: 2,
    user_reply_bot: 3
  }

  def hi_message
    if user?
      "💭 New toruya user message, user_id: #{social_user.user_id}, user: #{social_user.social_user_name}, content: #{raw_content}, #{Rails.application.routes.url_helpers.admin_chats_url(social_service_user_id: social_user.social_service_user_id)}"
    end
  end
end
