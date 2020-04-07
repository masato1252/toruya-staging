require "line_client"

class Lines::MessageEvent < ActiveInteraction::Base
  hash :event
  object :social_customer

  def execute
    message = {
      type: 'text',
      text: "hello message #{event[:message][:text]}"
    }

    LineClient.reply(social_customer, events["replyToken"], message)

    LineClient.reply(social_customer, reply_token, message)
  end
end
