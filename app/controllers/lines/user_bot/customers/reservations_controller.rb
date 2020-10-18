class Lines::UserBot::Customers::ReservationsController < Lines::UserBotDashboardController
  before_action :set_customer, only: [:index]

  def index
    head :unprocessable_entity if cannot?(:read, @customer)

    @reservation_customers =
      @customer.reservation_customers
        .includes(reservation: [ :menus, :active_reservation_customers, :reservation_menus, :customers, :staffs, shop: :user, reservation_staffs: [ :menu, :staff ] ])
        .merge(Reservation.active)
        .order("reservations.start_time DESC")

    render json: {
      reservations: view_context.reservation_customer_options(@reservation_customers)
    }
  end

  def accept
    ReservationCustomers::Accept.run!(reservation_id: params[:reservation_id], customer_id: params[:customer_id])

    redirect_back fallback_location: SiteRouting.new(view_context).customers_path(super_user.id, customer_id: params[:customer_id])
  end

  def pend
    ReservationCustomers::Pend.run!(reservation_id: params[:reservation_id], customer_id: params[:customer_id])

    redirect_back fallback_location: SiteRouting.new(view_context).customers_path(super_user.id, customer_id: params[:customer_id])
  end

  def cancel
    ReservationCustomers::Cancel.run!(reservation_id: params[:reservation_id], customer_id: params[:customer_id])

    redirect_back fallback_location: SiteRouting.new(view_context).customers_path(super_user.id, customer_id: params[:customer_id])
  end

  private

  def set_customer
    @customer = super_user.customers.contact_groups_scope(current_user_staff).find(params[:customer_id])
  end
end
