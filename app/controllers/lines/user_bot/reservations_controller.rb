class Lines::UserBot::ReservationsController < Lines::UserBotDashboardController
  def show
    @reservation = Reservation.find(params[:id] || params[:reservation_form][:id])

    @sentences = view_context.reservation_staff_sentences(@reservation)
    @shop_user = @reservation.shop.user
    @user_ability = ability(@shop_user, @reservation.shop)
    @customer = Customer.find_by(id: params[:from_customer_id])
    @reservation_customer = ReservationCustomer.find_by(reservation_id: @reservation.id, customer_id: params[:from_customer_id])

    render template: params[:from_customer_id] ? "reservations/customer_reservation_show" : "reservations/show", layout: false
  end
end
