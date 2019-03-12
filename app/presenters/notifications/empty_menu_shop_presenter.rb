module Notifications
  class EmptyMenuShopPresenter < ::NotificationsPresenter
    def data(owner:, shop:, in_shop_dashboard: false)
      ability = Ability.new(current_user, owner, shop)

      # manager reqruied
      if ability.can?(:manage, Settings) && ability.cannot?(:create_shop_reservations_with_menu, shop)
        if in_shop_dashboard
          I18n.t("settings.menu.in_shop_dashboard_notification_message_html",
                 url: h.settings_user_menus_path(owner, shop_id: shop.id)
                )
        else
          I18n.t("settings.menu.notification_message_html",
                 shop_name: shop.display_name,
                 url: h.settings_user_menus_path(owner, shop_id: shop.id)
                )
        end
      end
    end
  end
end
