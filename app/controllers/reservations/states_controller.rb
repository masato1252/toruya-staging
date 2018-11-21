class Reservations::StatesController < DashboardController
  before_action :authorize_reservation

  def pend
    outcome = Reservations::Pend.run!(reservation: reservation, current_staff: current_user_staff)

    redirect_back fallback_location: member_path, notice: I18n.t("reservation.update_successfully_message")
  end

  def accept
    outcome = Reservations::Accept.run!(reservation: reservation, current_staff: current_user_staff)

    redirect_back fallback_location: member_path, notice: I18n.t("reservation.update_successfully_message")
  end

  def accept_in_group
    outcome = Reservations::Accept.run!(reservation: reservation, current_staff: current_user_staff)

    recent_pending_reservations = NotificationsPresenter.new(view_context, current_user).recent_pending_reservations

    if recent_pending_reservations.exists?
      next_pending_reservation = recent_pending_reservations.first.reservation
      redirect_to date_member_path(next_pending_reservation.start_time.to_s(:date), next_pending_reservation.id)
    else
      redirect_to member_path, notice: I18n.t("reservation.update_successfully_message")
    end
  end

  def check_in
    reservation.check_in!
    redirect_back fallback_location: member_path, notice: I18n.t("reservation.update_successfully_message")
  end

  def check_out
    reservation.check_out!
    redirect_back fallback_location: member_path, notice: I18n.t("reservation.update_successfully_message")
  end

  def cancel
    reservation.cancel!
    redirect_back fallback_location: member_path, notice: I18n.t("reservation.canceled_successfully_message")
  end

  private

  def reservation
    @reservation ||= shop.reservations.find(params[:reservation_id])
  end

  def authorize_reservation
    authorize! :operate, reservation
  end
end
