# frozen_string_literal: true
# == Schema Information
#
# Table name: social_user_messages
#
#  id                :bigint           not null, primary key
#  ai_uid            :string
#  content_type      :string
#  message_type      :integer
#  nth_time          :integer
#  raw_content       :text
#  readed_at         :datetime
#  scenario          :string
#  schedule_at       :datetime
#  sent_at           :datetime
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  admin_user_id     :integer
#  custom_message_id :integer
#  slack_message_id  :string
#  social_user_id    :integer          not null
#
# Indexes
#
#  custom_message_social_user_messages_index                (social_user_id,custom_message_id)
#  index_social_user_messages_on_social_user_id_and_ai_uid  (social_user_id,ai_uid)
#  message_scenario_index                                   (social_user_id,scenario)
#

class SocialUserMessage < ApplicationRecord
  include SayHi
  include MalwareScannable
  hi_channel_name "toruya_users_support"

  belongs_to :social_user, touch: true
  belongs_to :admin_user, class_name: "User", required: false
  has_one_attached :image
  scan_attachment :image

  scope :unread, -> { where(readed_at: nil) }
  scope :sent, -> { where.not(sent_at: nil) }
  scope :ordered, -> { order(Arel.sql("(CASE
                                        WHEN social_user_messages.sent_at IS NOT NULL THEN social_user_messages.sent_at
                                        WHEN social_user_messages.schedule_at IS NOT NULL THEN social_user_messages.schedule_at
                                        ELSE social_user_messages.created_at END) DESC, social_user_messages.id DESC"))  }

  scope :from_user, -> { where(message_type: [SocialUserMessage.message_types[:user], SocialUserMessage.message_types[:user_reply_bot]]) }
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
      "💭 `user_id: #{social_user.user_id}, #{social_user.social_user_name}` #{"<#{Rails.application.routes.url_helpers.admin_chats_url(social_service_user_id: social_user.social_service_user_id, locale: social_user.locale)}|chat link>"}
      #{message_content}"
    end
  end
end
