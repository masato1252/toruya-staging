# frozen_string_literal: true

module SocialAccounts
  module RichMenus
    class SwitchToOfficial < ActiveInteraction::Base
      object :social_account

      def execute
        social_account.transaction do
          social_account.social_rich_menus.where(social_name: SocialAccounts::RichMenus::CustomerReservations::KEY).find_each do |rich_menu|
            compose(SocialAccounts::RichMenus::Delete, social_rich_menu: rich_menu)
          end

          social_account.social_rich_menus.find_or_create_by(social_name: SocialRichMenu::LINE_OFFICIAL_RICH_MENU_KEY)
        end
      end
    end
  end
end
