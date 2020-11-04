require "line_client"

class UserBotLines::MessageEvent < ActiveInteraction::Base
  USER_SIGN_OUT = "usersignout".freeze
  SETTINGS = I18n.t("toruya_line.keywords.settings").freeze

  hash :event, strip: false, default: nil
  object :social_user

  delegate :link_to, to: :helpers

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
            content: settings_message,
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

  private

  def settings_message
    [
      "#{SETTINGS}: #{url_helpers.lines_user_bot_settings_dashboard_url}"
    ].join("\n\n")
  end

  def url_helpers
    Rails.application.routes.url_helpers
  end

  def helpers
    ApplicationController.helpers
  end
end
