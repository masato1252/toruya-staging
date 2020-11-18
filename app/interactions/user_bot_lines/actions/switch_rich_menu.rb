require "line_client"

class UserBotLines::Actions::SwitchRichMenu < ActiveInteraction::Base
  object :social_user
  string :rich_menu_key

  def execute
    compose(
      RichMenus::Connect,
      social_target: social_user,
      social_rich_menu: ::SocialRichMenu.find_by!(social_name: rich_menu_key)
    )
  end
end
