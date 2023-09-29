# frozen_string_literal: true

require "line_client"

class UserBotLines::Actions::SwitchRichMenu < ActiveInteraction::Base
  object :social_user
  string :rich_menu_key

  def execute
    # TODO: Need to deal with other pending
    if rich_menu_key == UserBotLines::RichMenus::Dashboard::KEY &&
        (
          (user.social_account && user.social_account.social_messages.handleable.unread.exists?) ||
          user.pending_reservations.exists?
        )
      menu_key = UserBotLines::RichMenus::DashboardWithNotifications::KEY
    end

    menu_key ||= rich_menu_key

    if social_user.social_rich_menu_key != menu_key && !Rails.env.development?
      compose(
        ::RichMenus::Connect,
        social_target: social_user,
        social_rich_menu: ::SocialRichMenu.find_by!(social_name: menu_key)
      )
    end
  end

  private

  def user
    @user ||= social_user.user
  end
end
