require "line_client"

class UserBotLines::MessageEvent < ActiveInteraction::Base
  hash :event, strip: false, default: nil
  object :social_user

  def execute
    if event.present?
      case event["message"]["type"]
      when "text"
        compose(
          SocialUserMessages::Create,
          social_user: social_user,
          content: event["message"]["text"],
          readed: false,
          message_type: SocialUserMessage.message_types[:user]
        )
      else
        Rollbar.warning("Line chat room don't support message type", event: event)

        LineClient.send(social_user, "Sorry, we don't support this type of message yet, only support text for now.".freeze)
      end
    end
  end
end
