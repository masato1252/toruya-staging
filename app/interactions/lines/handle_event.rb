# frozen_string_literal: true

require "line_client"

class Lines::HandleEvent < ActiveInteraction::Base
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
  object :social_account

  def execute
    social_customer =
      begin
        SocialCustomer.transaction do
          SocialCustomer
            .create_with(social_rich_menu_key: SocialAccounts::RichMenus::CustomerReservations::KEY)
            .find_or_create_by(
              user_id: social_account.user_id,
              social_user_id: event[EVENT_SOURCE_KEY][EVENT_USER_ID_KEY],
              social_account_id: social_account.id)
        end
      rescue ActiveRecord::RecordNotUnique
        retry
      end

    if social_customer.social_user_name.blank?
      response = LineClient.profile(social_customer)

      if response.is_a?(Net::HTTPOK)
        body = JSON.parse(response.body)
        social_customer.update(social_user_name: body[SOCIAL_USER_NAME_KEY], social_user_picture_url: body[SOCIAL_USER_PICTURE_KEY])
      end
    end

    case event[EVENT_TYPE_KEY]
    when *SUPPORT_TYPES
      # Lines::MessageEvent
      # Lines::FollowEvent
      # Lines::PostbackEvent
      "Lines::#{event[EVENT_TYPE_KEY].camelize}Event".constantize.run!(social_customer: social_customer, event: event)
    else
      Rollbar.warning("Unexpected event type".freeze,
        social_account_id: social_account.id,
        event: event
      )
    end
  end
end
