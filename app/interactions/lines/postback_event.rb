require "line_client"

class Lines::PostbackEvent < ActiveInteraction::Base
  EVENT_ACTION_KEY = "action".freeze
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
  #       "data":"action=booking_pages",
  #       "params":{
  #          "datetime":"2017-12-25T01:00"
  #       }
  #    }
  # }
  hash :event, strip: false
  object :social_customer

  def execute
    data = Rack::Utils.parse_nested_query(event["postback".freeze]["data".freeze])

    case data[EVENT_ACTION_KEY]
    when *Lines::FeaturesButton::ACTION_TYPES
      SocialMessages::Create.run!(
        social_customer: social_customer,
        content: data[EVENT_ACTION_KEY],
        readed: true,
        message_type: SocialMessage.message_types[:customer_reply_bot]
      )

      "Lines::Actions::#{data[EVENT_ACTION_KEY].camelize}".constantize.run!(social_customer: social_customer)
    else
      Rollbar.warning("Unexpected action type".freeze,
        social_customer_id: social_customer.id,
        event: event
      )
    end
  end
end
