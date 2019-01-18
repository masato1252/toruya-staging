module Notifications
  class EmptyReservationSettingUserPresenter < ::NotificationsPresenter
    def data(staff_account:)
      owner = staff_account.owner
      ability = Ability.new(current_user, owner)

      # manager reqruied
      if ability.can?(:manage, Settings) && ability.cannot?(:create, :reservation_with_settings)
        I18n.t("settings.reservation_setting.notification_message_html", user_name: owner.name, url: h.new_settings_user_reservation_setting_path(owner, shop_id: staff_account.staff.shop_ids.first))
      end
    end
  end
end
