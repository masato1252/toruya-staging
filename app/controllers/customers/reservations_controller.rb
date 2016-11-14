class Customers::ReservationsController < DashboardController
  before_action :set_customer, only: [:index]

  def index
    @reservations = @customer.reservations
    .includes(:menu, :customers, :staffs)
    .order("reservations.start_time DESC")
  end

  def change_state
    reservation = @customer.reservations.find(params[:reservation_id])
    reservation.public_send("#{params[:action]}!")
  end

  private

  def set_customer
    @customer = current_user.customers.find(params[:id])
  end
end
