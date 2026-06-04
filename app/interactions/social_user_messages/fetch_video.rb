# frozen_string_literal: true

require "line_client"

module SocialUserMessages
  class FetchVideo < ActiveInteraction::Base
    object :social_user_message

    def execute
      message_body = JSON.parse(social_user_message.raw_content)
      return if message_body["originalContentUrl"].present?

      response = LineClient.message_content(
        social_customer: social_user_message.social_user,
        message_id: message_body["messageId"]
      )
      return if response.nil?

      tf = Tempfile.open(["content", ".mp4"], binmode: true)
      tf.write(response.body)
      tf.rewind
      social_user_message.video.attach(io: tf, filename: "video.mp4", content_type: "video/mp4")
      tf.close

      social_user_message.update(
        raw_content: message_body.merge(
          originalContentUrl: Rails.application.routes.url_helpers.url_for(social_user_message.video),
          previewImageUrl: message_body["previewImageUrl"].presence || ContentHelper::VIDEO_THUMBNAIL_URL
        ).to_json
      )
    end
  end
end
