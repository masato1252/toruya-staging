# frozen_string_literal: true

require "line_client"

module RichMenus
  class SetDefault < ActiveInteraction::Base
    object :social_rich_menu

    def execute
      response = ::LineClient.set_default_rich_menu(social_rich_menu)

      if response.is_a?(Net::HTTPOK)
        social_rich_menu.with_lock do
          social_rich_menu.account.social_rich_menus.update_all(default: nil)
          social_rich_menu.update(default: true)
        end
      end
    end
  end
end
