module RichMenus
  class Delete < ActiveInteraction::Base
    object :social_rich_menu

    def execute
      LineClient.delete_rich_menu(social_rich_menu)
      social_rich_menu.destroy
    end
  end
end
