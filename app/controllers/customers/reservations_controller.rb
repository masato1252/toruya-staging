class Customers::ReservationsController < DashboardController
  before_action :set_customer, only: [:index, :state]

  def index
    @reservations = @customer.reservations
    .includes(:menu, :customers, :staffs, :shop)
    .order("reservations.start_time DESC")
  end

  def state
    reservation = @customer.reservations.find(params[:reservation_id])
    reservation.public_send("#{params[:reservation_action]}!")

    redirect_to user_customers_path(super_user, shop_id: params[:shop_id], customer_id: params[:id])
  end

  def edit
    redirect_to edit_shop_reservation_path(
      shop_id: params[:shop_id],
      id: params[:reservation_id],
      from_shop_id: params[:from_shop_id],
      from_customer_id: params[:from_customer_id]
    )
  end

  private

  def set_customer
    @customer = super_user.customers.find(params[:id])
  end
end
