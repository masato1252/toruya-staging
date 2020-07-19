require "line_client"

class Lines::FollowEvent < ActiveInteraction::Base
  hash :event, strip: false
  object :social_customer

  def execute
    LineClient.send(social_customer, I18n.t("line.bot.thanks_follow"))
    compose(Lines::Features, social_customer: social_customer)
  end
end
