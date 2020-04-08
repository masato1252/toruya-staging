class Lines::HandleEvent < ActiveInteraction::Base
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
    social_customer = SocialCustomer.find_or_create_by(
      user_id: social_account.user_id,
      social_user_id: event["source"]["userId"],
      social_account_id: social_account.id
    )

    case event["type"]
    when "message", "follow", "postback"
      # Lines::MessageEvent
      # Lines::FollowEvent
      # Lines::PostbackEvent
      "Lines::#{event["type"].camelize}Event".constantize.run!(social_customer: social_customer, event: event)
    else
      Rollbar.warning("Unexpected event type",
        social_account_id: social_account.id,
        event: event
      )
    end
  end
end
