class NotificationsPresenter
  attr_reader :current_user, :view_context

  def initialize(view_context, current_user)
    @view_context = view_context
    @current_user = current_user
  end

  def data
    new_pending_reservations + new_staff_accounts
  end

  private

  def new_pending_reservations
    staff_ids = current_user.staff_accounts.active.pluck(:staff_id)

    reservation_staffs = ReservationStaff.pending.where(staff_id: staff_ids).includes(reservation: :shop).where("reservations.aasm_state": :pending).map do |reservation_staff|
      res = reservation_staff.reservation
      "#{I18n.t("notifications.pending_reservation_need_confirm")} #{view_context.link_to(I18n.t("notifications.pending_reservation_confirm"), view_context.date_member_path(res.start_time.to_s(:date), res.id))}"
    end
  end

  def new_staff_accounts
    current_user.staffs.active_without_data.includes(:staff_account).map do |staff|
      "#{I18n.t("settings.staff_account.new_staff_active")} #{view_context.link_to(I18n.t("settings.staff_account.staff_setting"), view_context.edit_settings_user_staff_path(current_user, staff, shop_id: current_user.shop_ids.first))}"
    end
  end
end
