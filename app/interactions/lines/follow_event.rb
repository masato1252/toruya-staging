require "line_client"

class Lines::FollowEvent < ActiveInteraction::Base
  hash :event
  object :social_customer

  def execute
    message = {
      type: 'text',
      text: "hello User #{event["source"]["userId"]}"
    }

    LineClient.reply(social_customer, events["replyToken"], message)
  end
end
