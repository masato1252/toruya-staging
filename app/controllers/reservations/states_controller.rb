class Reservations::StatesController < DashboardController
  def pend
    outcome = Reservations::Pend.run!(reservation: reservation, current_staff: current_user_staff)

    redirect_back fallback_location: member_path, notice: I18n.t("reservation.update_successfully_message")
  end

  def accept
    outcome = Reservations::Accept.run!(reservation: reservation, current_staff: current_user_staff)

    redirect_back fallback_location: member_path, notice: I18n.t("reservation.update_successfully_message")
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
end
