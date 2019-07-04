class Customers::ReservationsController < DashboardController
  before_action :set_customer, only: [:index, :state]

  def index
    head :unprocessable_entity if cannot?(:read, @customer)

    @reservations = @customer.reservations
    .includes(:menus, :customers, :staffs, shop: :user)
    .order("reservations.start_time DESC")
  end

  private

  def set_customer
    @customer = super_user.customers.contact_groups_scope(current_user_staff).find(params[:id])
  end
end
