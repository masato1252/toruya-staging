module SocialAccounts
  module RichMenus
    class SwitchBackToruya < ActiveInteraction::Base
      object :social_account

      def execute
        if rich_menu = social_account.social_rich_menus.find_by(social_name: SocialRichMenu::LINE_OFFICIAL_RICH_MENU_KEY)
          rich_menu.destroy
        end

        SocialAccounts::RichMenus::CustomerReservations.run(social_account: social_account)
      end
    end
  end
end
