class NotificationsPresenter
  attr_reader :current_user, :view_context

  def initialize(view_context, current_user)
    @view_context = view_context
    @current_user = current_user
  end

  def data
    new_pending_reservations
  end

  private

  def new_pending_reservations
    staff_ids = current_user.staff_accounts.active.pluck(:staff_id)

    reservation_staffs = ReservationStaff.where(staff_id: staff_ids, state: ReservationStaff.states[:pending]).includes(reservation: :shop).where("reservations.aasm_state": :pending).map do |reservation_staff|
      "#{I18n.t("notifications.pending_reservation_need_confirm")} #{view_context.link_to(I18n.t("notifications.pending_reservation_confirm"), view_context.accept_shop_reservation_states_path(reservation_staff.reservation.shop, reservation_staff.reservation))}"
    end
  end
end
