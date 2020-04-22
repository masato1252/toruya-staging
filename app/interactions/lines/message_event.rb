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
    actions = [
      {
        "type": "postback",
        "label": "All activities",
        "data": "action=booking_pages"
      },
      {
        "type": "postback",
        "label": "Shop phone number",
        "data": "action=shop_phone"
      },
    ].freeze

    LineClient.button_template(
      social_customer: social_customer,
      title: "Welcome to my shops".freeze,
      text: "These are the services we provide".freeze,
      actions: actions
    )
  end
end
