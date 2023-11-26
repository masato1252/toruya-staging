# frozen_string_literal: true

require "line_client"

module RichMenus
  class SetCurrent < ActiveInteraction::Base
    object :social_rich_menu

    def execute
      social_rich_menu.with_lock do
        social_rich_menu.account.social_rich_menus.update_all(current: nil)
        social_rich_menu.update(current: true)
      end

      # Link rich menu to social customer
      SocialAccounts::RichMenus::Connect.perform_later(social_rich_menu: social_rich_menu)
    end
  end
end
