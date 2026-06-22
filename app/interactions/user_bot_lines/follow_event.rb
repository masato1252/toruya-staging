# frozen_string_literal: true

require "line_client"

class UserBotLines::FollowEvent < ActiveInteraction::Base
  hash :event, strip: false
  object :social_user

  def execute
    LineClient.send(social_user, I18n.t("toruya_line.bot.thanks_follow", trial_days: Plan::TRIAL_PLAN_THRESHOLD_DAYS))
    UserBotLines::RichMenus::Expo2026Campaign.link_nologin_menu(social_user)
    Notifiers::Users::VideoForUserFollowing.perform_later(receiver: social_user)
  end
end
