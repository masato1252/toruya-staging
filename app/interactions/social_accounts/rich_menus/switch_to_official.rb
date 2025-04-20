# frozen_string_literal: true

module SocialAccounts
  module RichMenus
    class SwitchToOfficial < ActiveInteraction::Base
      object :social_account

      def execute
        return if social_account.current_rich_menu&.official?

        social_account.transaction do
          social_account.social_rich_menus.find_each do |rich_menu|
            compose(::RichMenus::Delete, social_rich_menu: rich_menu)
          end

          new_current_rich_menu = social_account.social_rich_menus.find_or_create_by(social_name: SocialRichMenu::LINE_OFFICIAL_RICH_MENU_KEY)
          new_current_rich_menu.update(current: true)

          social_account.social_customers.update_all(social_rich_menu_key: SocialRichMenu::LINE_OFFICIAL_RICH_MENU_KEY)
        end
      end
    end
  end
end
