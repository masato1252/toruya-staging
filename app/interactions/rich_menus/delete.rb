# frozen_string_literal: true

module RichMenus
  class Delete < ActiveInteraction::Base
    object :social_rich_menu

    def execute
      response = LineClient.delete_rich_menu(social_rich_menu)

      if response.is_a?(Net::HTTPOK)
        social_rich_menu.image.purge_later if social_rich_menu.image
        social_rich_menu.destroy
      end
    end
  end
end
