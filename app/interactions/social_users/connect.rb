require "line_client"

module SocialUsers
  class Connect < ActiveInteraction::Base
    object :user
    object :social_user
    boolean :change_rich_menu, default: true

    def execute
      social_user.update!(user: user)

      if change_rich_menu && Rails.env.production?
        LineClient.link_rich_menu(
          social_customer: social_user,
          social_rich_menu: SocialRichMenu.find_by!(social_name: UserBotLines::RichMenus::Dashboard::KEY)
        )
      end
    end
  end
end
