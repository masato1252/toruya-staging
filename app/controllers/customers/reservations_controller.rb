class Customers::ReservationsController < DashboardController
  before_action :set_customer, only: [:index, :state]

  def index
    head :unprocessable_entity if cannot?(:read, @customer)

    @reservations = @customer.reservations
    .includes(:menu, :customers, :staffs, shop: :user)
    .order("reservations.start_time DESC")
  end

  def state
    head :unprocessable_entity if cannot?(:read, @customer)

    reservation = @customer.reservations.find(params[:reservation_id])

    case params[:reservation_action]
    when "accept"
      Reservations::Accept.run!(reservation: reservation, current_staff: current_user_staff)
    when "pend"
      Reservations::Pend.run!(reservation: reservation, current_staff: current_user_staff)
    else
      reservation.public_send("#{params[:reservation_action]}!")
    end

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
    @customer = super_user.customers.contact_groups_scope(current_user_staff).find(params[:id])
  end
end
