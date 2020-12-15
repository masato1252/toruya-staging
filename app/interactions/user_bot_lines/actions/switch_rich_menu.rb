require "line_client"

class UserBotLines::Actions::SwitchRichMenu < ActiveInteraction::Base
  object :social_user
  string :rich_menu_key

  def execute
    if rich_menu_key == UserBotLines::RichMenus::Dashboard::KEY &&
        social_user.user.social_account.social_messages.includes(social_customer: :customer).unread.exists?
      menu_key = UserBotLines::RichMenus::DashboardWithNotifications::KEY
    end

    menu_key ||= rich_menu_key

    # TODO: don't switch if the same
    compose(
      RichMenus::Connect,
      social_target: social_user,
      social_rich_menu: ::SocialRichMenu.find_by!(social_name: menu_key)
    )
  end
end
