module Menus
  class Delete < ActiveInteraction::Base
    object :menu

    def execute
      menu.with_lock do
        menu.update_columns(deleted_at: Time.current)
        MenuCategory.where(menu_id: menu.id).destroy_all
      end
    end
  end
end
