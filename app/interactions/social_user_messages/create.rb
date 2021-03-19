# frozen_string_literal: true

require "line_client"
require "webpush_client"

module SocialUserMessages
  class Create < ActiveInteraction::Base
    TEXT_TYPE = "text"
    VIDEO_TYPE = "video"
    CONTENT_TYPES = [TEXT_TYPE, VIDEO_TYPE].freeze

    object :social_user
    string :content
    string :content_type, default: TEXT_TYPE
    boolean :readed
    integer :message_type

    validates :content_type, presence: true, inclusion: { in: CONTENT_TYPES }

    def execute
      message = SocialUserMessage.create(
        social_user: social_user,
        raw_content: content,
        readed_at: readed ? Time.zone.now : nil,
        message_type: message_type
      )

      if message.errors.present?
        errors.merge!(message.errors)
      elsif message_type == SocialUserMessage.message_types[:bot] || message_type == SocialUserMessage.message_types[:admin]
        if content_type == TEXT_TYPE
          LineClient.send(social_user, content)
        else
          LineClient.send_video(social_user, content)
        end
      elsif !readed && message_type == SocialUserMessage.message_types[:user]
        AdminChannel.broadcast_to(
          AdminChannel::CHANNEL_NAME,
          {
            type: "customer_new_message",
            data: {
              customer: SocialUserSerializer.new(social_user).attributes_hash,
              message: SocialUserMessageSerializer.new(message).attributes_hash
            }
          }
        )

        WebPushSubscription.where(user_id: User.admin.pluck(:id)).each do |subscription|
          begin
            WebpushClient.send(
              subscription: subscription,
              message: {
                title: "#{social_user.social_user_name} send a message",
                body: content,
                url: Rails.application.routes.url_helpers.admin_chats_url(social_service_user_id: social_user.social_user_id)
              }
            )
          rescue Webpush::InvalidSubscription, Webpush::ExpiredSubscription, Webpush::Unauthorized => e
            Rollbar.error(e)

            subscription.destroy
          rescue => e
            Rollbar.error(e)
          end
        end
      end

      message
    end
  end
end
