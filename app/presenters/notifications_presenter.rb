class NotificationsPresenter
  attr_reader :current_user, :view_context

  def initialize(view_context, current_user)
    @view_context = view_context
    @current_user = current_user
  end

  def data
    new_pending_reservations + new_staff_accounts
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
      "#{I18n.t("notifications.pending_reservation_need_confirm", number: recent_pending_reservations.count)} #{view_context.link_to(I18n.t("notifications.pending_reservation_confirm"), view_context.date_member_path(oldest_res.start_time.to_s(:date), oldest_res.id))}"
    ] : []
  end

  def new_staff_accounts
    current_user.staffs.active_without_data.includes(:staff_account).map do |staff|
      "#{I18n.t("settings.staff_account.new_staff_active")} #{view_context.link_to(I18n.t("settings.staff_account.staff_setting"), view_context.edit_settings_user_staff_path(current_user, staff, shop_id: current_user.shop_ids.first))}"
    end
  end
end
