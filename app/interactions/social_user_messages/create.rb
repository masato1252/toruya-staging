# frozen_string_literal: true

require "line_client"
require "webpush_client"

module SocialUserMessages
  class Create < ActiveInteraction::Base
    TEXT_TYPE = "text"
    VIDEO_TYPE = "video"
    IMAGE_TYPE = "image"
    FLEX_TYPE = "flex"
    CONTENT_TYPES = [TEXT_TYPE, VIDEO_TYPE, IMAGE_TYPE, FLEX_TYPE].freeze

    object :social_user
    object :content, class: Object # hash or string
    string :content_type, default: TEXT_TYPE
    boolean :readed
    integer :message_type
    time :schedule_at, default: nil

    validates :content_type, presence: true, inclusion: { in: CONTENT_TYPES }

    def execute
      message = SocialUserMessage.create(
        social_user: social_user,
        raw_content: content_type == FLEX_TYPE ? content["altText"] : content,
        readed_at: readed ? Time.zone.now : nil,
        message_type: message_type,
        schedule_at: schedule_at
      )

      if message.errors.present?
        errors.merge!(message.errors)
      elsif message_type == SocialUserMessage.message_types[:bot] || message_type == SocialUserMessage.message_types[:admin]
        case content_type
        when TEXT_TYPE
          if schedule_at
            SocialUserMessages::Send.perform_at(schedule_at: schedule_at, social_user_message: message)
          else
            SocialUserMessages::Send.run(social_user_message: message)
          end
        when VIDEO_TYPE
          LineClient.send_video(social_user, content)
        when IMAGE_TYPE
          LineClient.send_image(social_user, content)
        when FLEX_TYPE
          LineClient.flex(social_user, content)
        end
      elsif !readed && message_type == SocialUserMessage.message_types[:user]
        message.update(sent_at: Time.current)

        case content_type
        when IMAGE_TYPE
          SocialUserMessages::FetchImage.perform_later(social_user_message: message)
        end
      end

      message
    end
  end
end
