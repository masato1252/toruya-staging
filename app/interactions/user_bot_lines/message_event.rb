# frozen_string_literal: true

require "line_client"
require "message_encryptor"

class UserBotLines::MessageEvent < ActiveInteraction::Base
  USER_SIGN_OUT = "usersignout".freeze

  hash :event, strip: false, default: nil
  object :social_user

  def execute
    if event.present?
      case event["message"]["type"]
      when "image"
        compose(
          SocialUserMessages::Create,
          social_user: social_user,
          content: {
            messageId: event["message"]["id"],
            originalContentUrl: event["message"]["contentProvider"]["originalContentUrl"],
            previewImageUrl: event["message"]["contentProvider"]["previewImageUrl"]
          }.to_json,
          readed: false,
          content_type: SocialUserMessages::Create::IMAGE_TYPE,
          message_type: SocialUserMessage.message_types[:user]
        )
      when "text"
        compose(
          SocialUserMessages::Create,
          social_user: social_user,
          content: event["message"]["text"],
          readed: false,
          message_type: SocialUserMessage.message_types[:user]
        )

        case event["message"]["text"].strip
        when USER_SIGN_OUT
          SocialUsers::Disconnect.run(social_user: social_user)
        else
          SocialUserMessages::Create.perform_debounce(
            social_user: social_user,
            content: I18n.t("toruya_line.bot.auto_reply_for_user_message"),
            readed: true,
            message_type: SocialUserMessage.message_types[:bot],
          )
          Notifiers::Users::AiSupportFlex.perform_debounce(receiver: social_user)
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
