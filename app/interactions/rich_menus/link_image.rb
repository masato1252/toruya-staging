# frozen_string_literal: true

require "line_client"

module RichMenus
  class LinkImage < ActiveInteraction::Base
    object :social_account
    object :social_rich_menu

    def execute
      ::LineClient.create_rich_menu_image(
        social_account: social_account,
        rich_menu_id: social_rich_menu.social_rich_menu_id,
        file_path: file_url_or_path
      )
    end

    private

    def file_url_or_path
      if social_rich_menu.image.attached?
        social_rich_menu.image.url
      else
        File.join(Rails.root, "app", "assets", "images", "rich_menus", "#{social_rich_menu.social_name}.png")
      end
    end
  end
end
