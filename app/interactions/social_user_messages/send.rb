require "line_client"

module SocialUserMessages
  class Send < ActiveInteraction::Base
    object :social_user_message

    def execute
      response =
        case content_type
        when SocialUserMessages::Create::TEXT_TYPE
          LineClient.send(social_user, content)
        when SocialUserMessages::Create::VIDEO_TYPE
          LineClient.send_video(social_user, content)
        when SocialUserMessages::Create::IMAGE_TYPE
          LineClient.send_image(social_user, content)
        when SocialUserMessages::Create::FLEX_TYPE
          LineClient.flex(social_user, content)
        end

      if response.code == "200"
        social_user_message.update(sent_at: Time.current)
      else
        error_message = begin
          JSON.parse(response.body)["message"]
        rescue TypeError, JSON::ParserError
          "Toruya User message sent failed"
        end

        if response.code == "429"
          SlackClient.send(channel: 'sayhi', text: "💣 LINEのメッセージ通数が上限に達したため、顧客にメッセージ送信できませんでした")
        end

        errors.add(:social_user_message, :sent_failed, message: "^#{error_message}")
      end
    end

    private

    def social_user
      social_user_message.social_user
    end

    def content
      social_user_message.raw_content
    end

    def content_type
      social_user_message.content_type
    end
  end
end
