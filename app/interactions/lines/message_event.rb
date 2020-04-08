require "line_client"

class Lines::MessageEvent < ActiveInteraction::Base
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
  hash :event, strip: false
  object :social_customer

  def execute
    message = {
      type: 'text',
      text: "hello message #{event["message"]["text"]}"
    }

    LineClient.reply(social_customer, event["replyToken"], message)
  end
end
