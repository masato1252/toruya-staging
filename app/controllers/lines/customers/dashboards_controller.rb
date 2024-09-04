class Lines::Customers::DashboardsController < Lines::CustomersController
  def reservations
    upcoming_reservations = current_customer.reservations.future.uncanceled.pluck(:id)
    upcoming_reservation_customers = ReservationCustomer.where(reservation: upcoming_reservations, customer: current_customer).includes(:reservation).order("reservations.start_time": :desc).references(:reservations)
    past_reservations = current_customer.reservations.past.where(aasm_state: %w(pending reserved checked_in checked_out)).active.limit(20).pluck(:id)
    past_reservation_customers = ReservationCustomer.where(reservation: past_reservations, customer: current_customer).includes(:reservation).order("reservations.start_time": :desc).references(:reservations)

    @reservations = upcoming_reservations + past_reservations
    @reservation_customers = upcoming_reservation_customers + past_reservation_customers
  end

  def online_services
    online_service_relations = current_customer.online_service_customer_relations.includes(:online_service).order("online_service_customer_relations.id DESC")
    online_service_applications = current_customer.online_service_customer_applications.includes(:online_service).order("online_service_customer_relations.id DESC").limit(20)
    unavailable_online_service_relations = online_service_applications - online_service_relations
    @online_service_relations = online_service_relations + unavailable_online_service_relations
  end

  private

  def current_owner
    @current_owner ||= User.find_by(public_id: params[:public_id])
  end
  helper_method :current_owner
end
