# frozen_string_literal: true

require "line_client"

module RichMenus
  class Connect < ActiveInteraction::Base
    object :social_target, class: ApplicationRecord # social_user or social_customer
    object :social_rich_menu

    def execute
      response = LineClient.link_rich_menu(social_customer: social_target, social_rich_menu: social_rich_menu)
      social_target.update(social_rich_menu_key: social_rich_menu.social_name) if response.is_a?(Net::HTTPOK)
    end
  end
end
