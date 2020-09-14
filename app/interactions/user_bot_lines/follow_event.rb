require "line_client"

class UserBotLines::FollowEvent < ActiveInteraction::Base
  hash :event, strip: false
  object :social_user

  def execute
    LineClient.send(social_user, I18n.t("toruya_line.bot.thanks_follow"))
  end
end
