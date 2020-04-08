require "line_client"

class Lines::FollowEvent < ActiveInteraction::Base
  hash :event, strip: false
  object :social_customer

  def execute
    message = {
      type: 'text',
      text: "hello User #{event["source"]["userId"]}"
    }

    LineClient.reply(social_customer, event["replyToken"], message)
  end
end
