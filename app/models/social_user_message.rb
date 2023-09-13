# frozen_string_literal: true
# == Schema Information
#
# Table name: social_user_messages
#
#  id               :bigint           not null, primary key
#  content_type     :string
#  message_type     :integer
#  nth_time         :integer
#  raw_content      :text
#  readed_at        :datetime
#  scenario         :string
#  schedule_at      :datetime
#  sent_at          :datetime
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  admin_user_id    :integer
#  slack_message_id :string
#  social_user_id   :integer          not null
#
# Indexes
#
#  message_scenario_index  (social_user_id,scenario)
#

class SocialUserMessage < ApplicationRecord
  include SayHi
  hi_channel_name "toruya_users_support"

  belongs_to :social_user, touch: true
  has_one_attached :image

  scope :unread, -> { where(readed_at: nil) }
  scope :sent, -> { where.not(sent_at: nil) }

  enum message_type: {
    bot: 0,
    admin: 1,
    user: 2,
    user_reply_bot: 3,
    user_ai_question: 4,
    user_ai_response: 5
  }

  def hi_message
    message_content =
      begin
        content = JSON.parse(raw_content)

        if image.attached?
          "<#{Images::Process.run!(image: image, resize: "750")}|content>"
        elsif content_type == SocialUserMessages::Create::FLEX_TYPE
          content["altText"]
        else
          content
        end
      rescue TypeError, JSON::ParserError
        raw_content
      end

    if user?
      "💭 `user_id: #{social_user.user_id}, #{social_user.social_user_name}` #{"<#{Rails.application.routes.url_helpers.admin_chats_url(social_service_user_id: social_user.social_service_user_id)}|chat link>"}
      #{message_content}"
    end
  end
end
