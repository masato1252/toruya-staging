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

  def recent
    @customers =
      super_user
      .customers
      .contact_groups_scope(current_user_staff)
      .includes(:social_customer, :rank, :contact_group, updated_by_user: :profile)
      .order("updated_at DESC, id DESC")
      .where(
        "customers.updated_at < :last_updated_at OR
        (customers.updated_at = :last_updated_at AND customers.id < :last_updated_id)",
        last_updated_at: params["last_updated_at"] ? Time.parse(params["last_updated_at"]) : Time.current,
        last_updated_id: params["last_updated_id"] || INTEGER_MAX)
      .limit(Customers::Search::PER_PAGE)

    render template: "customers/query"
  end

  def search
    @customers = Customers::Search.run(
      super_user: super_user,
      current_user_staff: current_user_staff,
      keyword: params[:keyword],
      page: params[:page].presence || 1
    ).result

    render template: "customers/query"
  end
end
