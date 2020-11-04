require "line_client"

module RichMenus
  class Connect < ActiveInteraction::Base
    object :social_target, class: ApplicationRecord # social_user or social_customer
    object :social_rich_menu

    def execute
      social_target.update(social_rich_menu_key: social_rich_menu.social_name)
      LineClient.link_rich_menu(social_customer: social_target, social_rich_menu: social_rich_menu)
    end
  end
end
