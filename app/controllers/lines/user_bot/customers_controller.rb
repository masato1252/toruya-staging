class Lines::UserBot::CustomersController < Lines::UserBotDashboardController
  def index
    authorize! :read, :customers_dashboard
    @body_class = "customer"

    @customers =
      super_user
      .customers
      .contact_groups_scope(current_user_staff)
      .includes(:social_customer, :rank, :contact_group, updated_by_user: :profile)
      .order("updated_at DESC")
      .limit(Customers::Search::PER_PAGE)
    @customer =
      super_user
      .customers
      .contact_groups_scope(current_user_staff)
      .includes(:rank, :contact_group, :social_customer).find_by(id: params[:customer_id])

    @reservation = ReservationCustomer.find_by(customer_id: params[:customer_id], reservation_id: params[:reservation_id])&.reservation

    if shop
      @add_reservation_path = form_shop_reservations_path(shop, params[:reservation_id])
    end

    # Notifications START
    @notification_messages = Notifications::PendingCustomerReservationsPresenter.new(view_context, current_user).data.compact + Notifications::NonGroupCustomersPresenter.new(view_context, current_user).data.compact
    # Notifications END
  end
end
