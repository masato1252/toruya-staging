require "line_client"

class UserBotLines::PostbackEvent < ActiveInteraction::Base
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
  #       "data":"action=switch_rich_menu&rich_menu_key=user_booking",
  #       "params":{
  #          "datetime":"2017-12-25T01:00"
  #       }
  #    }
  # }
  hash :event, strip: false
  object :social_user

  def execute
    data = Rack::Utils.parse_nested_query(event["postback"]["data"])

    case data[EVENT_ACTION_KEY]
    when UserBotLines::Actions::SwitchRichMenu.class_name
      UserBotLines::Actions::SwitchRichMenu.run(social_user: social_user, rich_menu_key: data["rich_menu_key"])
    when *others_actions
      SocialUserMessages::Create.run!(
        social_user: social_user,
        content: I18n.t("line.actions.label.#{data[EVENT_ACTION_KEY]}"),
        readed: true,
        message_type: SocialUserMessage.message_types[:user_reply_bot]
      )

      "UserBotLines::Actions::#{data[EVENT_ACTION_KEY].camelize}".constantize.run!(social_user: social_user)
    else
      Rollbar.warning("Unexpected action type".freeze,
        social_customer_id: social_customer.id,
        event: event
      )
    end
  end

  private

  def support_actions
    []
  end
end
