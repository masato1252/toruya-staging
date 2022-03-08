# frozen_string_literal: true

require "line_client"

class Lines::FollowEvent < ActiveInteraction::Base
  hash :event, strip: false
  object :social_customer

  def execute
    # Don't send follow message
    # https://toruya.slack.com/archives/C0201K35WMC/p1646709948010259?thread_ts=1646709569.318589&cid=C0201K35WMC
    # LineClient.send(social_customer, I18n.t("line.bot.thanks_follow"))
  end
end
