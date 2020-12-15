require "line_client"
require "message_encryptor"

class UserBotLines::MessageEvent < ActiveInteraction::Base
  USER_SIGN_OUT = "usersignout".freeze

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
        when "newmessages"
          LineClient.flex(
            social_user,
            LineMessages::FlexTemplateContainer.template(
              altText: "ご確認ください",
              contents: LineMessages::FlexTemplateContent.content4(
                title1: "ご確認ください",
                body1: "確認が必要なメッセージや予約があります。",
                action_templates: [
                  LineActions::Uri.new(
                    label: "メッセージを確認する",
                    url: Rails.application.routes.url_helpers.lines_user_bot_notifications_url(encrypted_social_service_user_id: MessageEncryptor.encrypt(social_user.social_service_user_id))
                  )
                ].map(&:template)
              )
            )
          )
        end
      else
        Rollbar.warning("Line chat room don't support message type", event: event)

        LineClient.send(social_user, "Sorry, we don't support this type of message yet, only support text for now.".freeze)
      end
    end
  end

  private

  def url_helpers
    Rails.application.routes.url_helpers
  end

  def helpers
    ApplicationController.helpers
  end
end
