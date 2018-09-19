class NotificationsPresenter
  attr_reader :current_user, :h
  delegate :link_to, to: :h

  def initialize(h, current_user)
    @h = h
    @current_user = current_user
  end

  def data
    new_pending_reservations + new_staff_accounts + empty_reservation_setting_users + empty_menu_shops
  end

  def recent_pending_reservations
    @recent_pending_reservations ||= begin
      staff_ids = current_user.staff_accounts.active.pluck(:staff_id)

      ReservationStaff.pending.where(staff_id: staff_ids).includes(reservation: :shop).where("reservations.aasm_state": :pending).order("reservations.start_time ASC")
    end
  end

  private

  def new_pending_reservations
    oldest_res = recent_pending_reservations.first&.reservation

    oldest_res ? [
      "#{I18n.t("notifications.pending_reservation_need_confirm", number: recent_pending_reservations.count)} #{link_to(I18n.t("notifications.pending_reservation_confirm"), h.date_member_path(oldest_res.start_time.to_s(:date), oldest_res.id))}"
    ] : []
  end

  def new_staff_accounts
    current_user.staffs.active_without_data.includes(:staff_account).map do |staff|
      "#{I18n.t("settings.staff_account.new_staff_active")} #{link_to(I18n.t("settings.staff_account.staff_setting"), h.edit_settings_user_staff_path(current_user, staff, shop_id: current_user.shop_ids.first))}"
    end
  end

  def empty_reservation_setting_users
    current_user.staff_accounts.includes(:user, :owner).each_with_object([]) do |staff_account, array|
      owner = staff_account.owner

      ability = Ability.new(staff_account.user, owner)

      # manager reqruied
      if ability.can?(:manage, Settings) && ability.cannot?(:create, :reservation_with_settings)
        array << I18n.t("settings.reservation_setting.notification_message_html", user_name: owner.name, url: h.new_settings_user_reservation_setting_path(owner, shop_id: staff_account.staff.shop_ids.first))
      end
      array
    end
  end

  def empty_menu_shops
    h.working_shop_options(include_user_own: true).each_with_object([]) do |shop_option, array|
      owner = shop_option.owner
      shop = shop_option.shop

      ability = Ability.new(current_user, owner)

      # manager reqruied
      if ability.can?(:manage, Settings) && ability.cannot?(:create_shop_reservations_with_menu, shop)
        array << I18n.t("settings.menu.notification_message_html", shop_name: shop.display_name, url: h.settings_user_menus_path(owner, shop_id: shop_option.shop_id))
      end
      array
    end
  end
end
