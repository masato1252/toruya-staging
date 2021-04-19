# frozen_string_literal: true

module SocialAccounts
  module RichMenus
    class SwitchBackToruya < ActiveInteraction::Base
      object :social_account

      def execute
        social_account.transaction do
          social_account.social_rich_menus.where(social_name: SocialRichMenu::LINE_OFFICIAL_RICH_MENU_KEY).find_each do |rich_menu|
            rich_menu.destroy
          end

          SocialAccounts::RichMenus::CustomerReservations.run(social_account: social_account)
        end
      end
    end
  end
end
