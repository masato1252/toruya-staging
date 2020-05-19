require "line_client"

class Lines::MessageEvent < ActiveInteraction::Base
  ACTIONS = [
    {
      type: "postback",
      action: "booking_pages",
    },
    {
      type: "postback",
      action: "shop_phone",
    },
    {
      type: "postback",
      action: "one_on_one"
    }
  ].freeze
  ACTION_TYPES = ACTIONS.map { |action| action[:action] }.freeze

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

    if social_customer.bot?
      LineClient.button_template(
        social_customer: social_customer,
        title: "Welcome to my shops".freeze,
        text: "These are the services we provide".freeze,
        actions: action_templates
      )

      SocialMessages::Create.run!(
        social_customer: social_customer,
        content: "These are the services we provide",
        readed: true,
        message_type: SocialMessage.message_types[:bot]
      )
    end
  end

  private

  def action_templates
    ACTIONS.map do |action|
      {
        "type": action[:type],
        "label": I18n.t("line.actions.label.#{action[:action]}"),
        "data": URI.encode_www_form(action.slice(:action))
      }
    end
  end
end
