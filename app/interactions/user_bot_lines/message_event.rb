require "line_client"

class UserBotLines::MessageEvent < ActiveInteraction::Base
  USER_SIGN_OUT = "usersignout".freeze
  SETTINGS = "settings".freeze

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
          readed: true,
          message_type: SocialUserMessage.message_types[:user]
        )

        case event["message"]["text"].strip
        when USER_SIGN_OUT
          SocialUsers::Disconnect.run(social_user: social_user)
        when SETTINGS
          SocialUserMessages::Create.run(
            social_user: social_user,
            content: "settings",
            readed: true,
            message_type: SocialUserMessage.message_types[:bot]
          )
        end
      else
        Rollbar.warning("Line chat room don't support message type", event: event)

        LineClient.send(social_user, "Sorry, we don't support this type of message yet, only support text for now.".freeze)
      end
    end
  end
end
