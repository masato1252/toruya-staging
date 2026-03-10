# frozen_string_literal: true

module SocialUsers
  class Connect < ActiveInteraction::Base
    object :user
    object :social_user
    boolean :change_rich_menu, default: true

    def execute
      social_user.update!(user: user)

      if change_rich_menu && Rails.env.production?
        dashboard_menu = SocialRichMenu.find_by(social_name: UserBotLines::RichMenus::Dashboard::KEY, locale: social_user.locale)
        if dashboard_menu
          RichMenus::Connect.run(
            social_target: social_user,
            social_rich_menu: dashboard_menu
          )
        else
          Rails.logger.warn "[SocialUsers::Connect] Dashboard rich menu not found for locale=#{social_user.locale}"
        end
      end
    end
  end
end
