module Notifications
  class EmptyMenuShopPresenter < ::NotificationsPresenter
    def data(owner:, shop:)
      ability = Ability.new(current_user, owner)

      # manager reqruied
      if ability.can?(:manage, Settings) && ability.cannot?(:create_shop_reservations_with_menu, shop)
        I18n.t("settings.menu.notification_message_html",
               shop_name: shop.display_name,
               url: h.settings_user_menus_path(owner, shop_id: shop.id)
              )
      end
    end
  end
end
