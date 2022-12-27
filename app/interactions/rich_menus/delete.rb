# frozen_string_literal: true

module RichMenus
  class Delete < ActiveInteraction::Base
    object :social_rich_menu

    def execute
      response = LineClient.delete_rich_menu(social_rich_menu)
      social_rich_menu.destroy if response.is_a?(Net::HTTPOK)
    end
  end
end
