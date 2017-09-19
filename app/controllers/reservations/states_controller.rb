class Reservations::StatesController < DashboardController
  def pend
    reservation.pend!
    redirect_to shop_reservations_path(shop, reservation_date: params[:reservation_date]), notice: I18n.t("reservation.update_successfully_message")
  end

  def accept
    reservation.accept!
    redirect_to shop_reservations_path(shop, reservation_date: params[:reservation_date]), notice: I18n.t("reservation.update_successfully_message")
  end

  def check_in
    reservation.check_in!
    redirect_to shop_reservations_path(shop, reservation_date: params[:reservation_date]), notice: I18n.t("reservation.update_successfully_message")
  end

  def check_out
    reservation.check_out!
    redirect_to shop_reservations_path(shop, reservation_date: params[:reservation_date]), notice: I18n.t("reservation.update_successfully_message")
  end

  def cancel
    reservation.cancel!
    redirect_to shop_reservations_path(shop, reservation_date: params[:reservation_date]), notice: I18n.t("reservation.canceled_successfully_message")
  end

  private
  def reservation
    @reservation ||= shop.reservations.find(params[:reservation_id])
  end
end
