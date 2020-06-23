require "line_client"

class Lines::MessageEvent < ActiveInteraction::Base
  IDENTIFY_SHOP_CUSTOMER = "identify_shop_customer".freeze

  ACTIONS = [
    LineActions::Postback.new(action: Lines::Actions::BookingPages.class_name, enabled: false),
    LineActions::Postback.new(action: Lines::Actions::ShopPhone.class_name, enabled: false),
    LineActions::Postback.new(action: Lines::Actions::OneOnOne.class_name, enabled: false),
    LineActions::Postback.new(action: Lines::Actions::IncomingReservations.class_name, enabled: true),
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
  hash :event, strip: false
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
      LineClient.button_template(
        social_customer: social_customer,
        title: "Welcome to my shops".freeze,
        text: desc_template,
        actions: action_templates
      )

      SocialMessages::Create.run!(
        social_customer: social_customer,
        content: chatroom_owner_message_content,
        readed: true,
        message_type: SocialMessage.message_types[:bot]
      )
    end
  end

  private

  def desc_template
    # must not be longer than 60 characters
    if social_customer.customer
      "These are the services we provide"
    else
      "Please Help us to connect your customer information"
    end
  end

  def action_templates
    if social_customer.customer
      ENABLED_ACTIONS
    else
      guest_actions
    end.map(&:template)
  end

  def chatroom_owner_message_content
    if social_customer.customer
      "These are the services we provide: #{ACTION_TYPES.join(", ")}"
    else
      "Customer try to identify themselves"
    end
  end

  def guest_actions
    [
      LineActions::Uri.new(
        action: Lines::MessageEvent::IDENTIFY_SHOP_CUSTOMER,
        url: Rails.application.routes.url_helpers.lines_identify_shop_customer_url(social_user_id: social_customer.social_user_id)
      )
    ]
  end
end
