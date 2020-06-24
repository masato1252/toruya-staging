require "line_client"

class Lines::MessageEvent < ActiveInteraction::Base
  IDENTIFY_SHOP_CUSTOMER = "identify_shop_customer".freeze

  ACTIONS = [
    LineMessages::Postback.new(action: Lines::Actions::BookingPages.class_name, enabled: false),
    LineMessages::Postback.new(action: Lines::Actions::ShopPhone.class_name, enabled: false),
    LineMessages::Postback.new(action: Lines::Actions::OneOnOne.class_name, enabled: false),
    LineMessages::Postback.new(action: Lines::Actions::IncomingReservations.class_name, enabled: true),
  ].freeze

  ENABLED_ACTIONS = ACTIONS.select(&:enabled).freeze
  ACTION_TYPES = ENABLED_ACTIONS.map(&:action).freeze

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
  hash :event, strip: false, default: nil
  object :social_customer

  def execute
    if event.present?
      case event["message"]["type"]
      when "text"
        SocialMessages::Create.run!(
          social_customer: social_customer,
          content: event["message"]["text"],
          readed: false,
          message_type: SocialMessage.message_types[:customer]
        )
      else
        Rollbar.warning("Line chat room don't support message type", event: event)

        if social_customer.one_on_one?
          LineClient.send(social_customer, "Sorry, we don't support this type of message yet, only support text for now.".freeze)
        end
      end
    end

    if social_customer.bot?
      compose(Lines::FeaturesButton, social_customer: social_customer)
    end
  end
end
