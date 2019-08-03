class Customers::ReservationsController < DashboardController
  before_action :set_customer, only: [:index, :state]

  def index
    head :unprocessable_entity if cannot?(:read, @customer)

    @reservation_customers = @customer.reservation_customers
    .includes(reservation: [ :menus, :customers, :staffs, shop: :user ])
    .order("reservations.start_time DESC")
  end

  def accept
    ReservationCustomers::Accept.run!(reservation_id: params[:reservation_id], customer_id: params[:customer_id])

    redirect_back fallback_location: user_customers_path(super_user, customer_id: params[:customer_id])
  end

  def pend
    ReservationCustomers::Pend.run!(reservation_id: params[:reservation_id], customer_id: params[:customer_id])

    redirect_back fallback_location: user_customers_path(super_user, customer_id: params[:customer_id])
  end

  def cancel
    ReservationCustomers::Cancel.run!(reservation_id: params[:reservation_id], customer_id: params[:customer_id])

    redirect_back fallback_location: user_customers_path(super_user, customer_id: params[:customer_id])
  end

  private

  def set_customer
    @customer = super_user.customers.contact_groups_scope(current_user_staff).find(params[:id])
  end
end
