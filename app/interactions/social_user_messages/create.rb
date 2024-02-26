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
    string :content
    string :content_type, default: TEXT_TYPE
    file :image, default: nil
    string :scenario, default: nil
    integer :nth_time, default: nil
    boolean :readed
    integer :message_type
    time :schedule_at, default: nil
    integer :custom_message_id, default: nil

    validates :content_type, presence: true, inclusion: { in: CONTENT_TYPES }
    validates :content, presence: true

    def execute
      message = SocialUserMessage.create(
        social_user: social_user,
        raw_content: content,
        readed_at: readed ? Time.zone.now : nil,
        message_type: message_type,
        content_type: content_type,
        scenario: scenario,
        nth_time: nth_time,
        schedule_at: schedule_at,
        custom_message_id: custom_message_id
      )

      if message.errors.present?
        errors.merge!(message.errors)
      elsif message_type == SocialUserMessage.message_types[:bot] || message_type == SocialUserMessage.message_types[:admin]
        if image.present?
          message.image.attach(io: image, filename: image.original_filename)
          message.update(
            raw_content: {
              originalContentUrl: Images::Process.run!(image: message.image, resize: "750"),
              previewImageUrl: Images::Process.run!(image: message.image, resize: "750")
            }.to_json
          )
        end

        if schedule_at
          SocialUserMessages::Send.perform_at!(schedule_at: schedule_at, social_user_message: message)
        else
          compose(SocialUserMessages::Send, social_user_message: message)
        end
      elsif !readed && message_type == SocialUserMessage.message_types[:user]
        message.update(sent_at: Time.current)
        message.social_user.update(pinned: true)

        case content_type
        when IMAGE_TYPE
          SocialUserMessages::FetchImage.perform_later(social_user_message: message)
        end
      end

      message
    end
  end
end
