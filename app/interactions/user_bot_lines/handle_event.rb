# frozen_string_literal: true

require "line_client"

class UserBotLines::HandleEvent < ActiveInteraction::Base
  SOCIAL_USER_NAME_KEY = "displayName".freeze
  SOCIAL_USER_PICTURE_KEY = "pictureUrl".freeze
  EVENT_SOURCE_KEY = "source".freeze
  EVENT_USER_ID_KEY = "userId".freeze
  EVENT_TYPE_KEY = "type".freeze
  SUPPORT_TYPES = %w(message follow postback).freeze

  # follow event
  # {
  #   "replyToken": "nHuyWiB7yP5Zw52FIkcQobQuGDXCTA",
  #   "type": "follow",
  #   "mode": "active",
  #   "timestamp": 1462629479859,
  #   "source": {
  #     "type": "user",
  #     "userId": "U4af4980629..."
  #   }
  # }
  #
  # message event
  #  {
  #    "type"=>"message", 
  #    "replyToken"=>"49f33fecfd2a4978b806b7afa5163685", 
  #    "source"=>{
  #      "userId"=>"Ua52b39df3279673c4856ed5f852c81d9",
  #      "type"=>"user"
  #    },
  #    "timestamp"=>1536052545913, 
  #    "message"=>{
  #      "type"=>"text", 
  #      "id"=>"8521501055275", 
  #      "text"=>"??"
  #    }
  #  }
  # },
  # {
  #    "type":"postback",
  #    "replyToken":"b60d432864f44d079f6d8efe86cf404b",
  #    "source":{
  #       "userId":"U91eeaf62d...",
  #       "type":"user"
  #    },
  #    "mode": "active",
  #    "timestamp":1513669370317,
  #    "postback":{
  #       "data":"action=buy&itemid=111",
  #       "params":{
  #          "datetime":"2017-12-25T01:00"
  #       }
  #    }
  # }
  hash :event, strip: false

  def execute
    social_user =
      begin
        SocialUser.transaction do
          SocialUser
            .create_with(social_rich_menu_key: UserBotLines::RichMenus::Guest::KEY)
            .find_or_create_by(social_service_user_id: event[EVENT_SOURCE_KEY][EVENT_USER_ID_KEY])
        end
      rescue ActiveRecord::RecordNotUnique
        retry
      end

    if social_user.social_user_name.blank?
      response = LineClient.profile(social_user)

      if response.is_a?(Net::HTTPOK)
        body = JSON.parse(response.body)
        social_user.update(social_user_name: body[SOCIAL_USER_NAME_KEY], social_user_picture_url: body[SOCIAL_USER_PICTURE_KEY])
      end
    end

    case event[EVENT_TYPE_KEY]
    when *SUPPORT_TYPES
      # UserBotLines::FollowEvent
      # UserBotLines::MessageEvent
      # UserBotLines::PostbackEvent
      "UserBotLines::#{event[EVENT_TYPE_KEY].camelize}Event".constantize.run!(social_user: social_user, event: event)
    else
      Rollbar.warning("Unexpected event type".freeze,
        social_user_id: social_user.id,
        event: event
      )
    end
  end
end
