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
      .limit(::Customers::Search::PER_PAGE)
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

  def filter
    @customers = Customers::CharFilter.run(
      super_user: super_user,
      current_user_staff: current_user_staff,
      pattern_number: params[:pattern_number],
      page: params[:page].presence || 1
    ).result

    render template: "customers/query"
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
      .limit(::Customers::Search::PER_PAGE)

    render template: "customers/query"
  end

  def search
    @customers = ::Customers::Search.run(
      super_user: super_user,
      current_user_staff: current_user_staff,
      keyword: params[:keyword],
      page: params[:page].presence || 1
    ).result

    render template: "customers/query"
  end

  def save
    outcome = ::Customers::Store.run(user: super_user, current_user: current_user, params: convert_params(params.permit!.to_h))

    if outcome.valid?
      customer = outcome.result

      render json: {
        status: "successful",
        redirect_to: SiteRouting.new(view_context).customers_path(customer.user_id, customer_id: customer.id)
      }

    else
      head :unprocessable_entity
    end
  end

  def data_changed
    authorize! :edit, Customer

    @reservation_customer = ReservationCustomer.find(params[:reservation_customer_id])
    @customer = @reservation_customer.customer
    @reservation = @reservation_customer.reservation

    render template: "customers/data_changed", layout: false
  end

  def save_changes
    authorize! :edit, Customer

    outcome = ::Customers::RequestUpdate.run(reservation_customer: ReservationCustomer.find(params[:reservation_customer_id]))

    if outcome.invalid?
      Rollbar.warning("Update customer changed data failed",
        errors_messages: outcome.errors.full_messages.join(", "),
        errors_details: outcome.errors.details,
        params: params
      )
    end

    head :ok
  end


  def toggle_reminder_premission
    customer = super_user.customers.contact_groups_scope(current_user_staff).find(params[:id])
    customer.update(reminder_permission: !customer.reminder_permission)

    render json: { reminder_permission: customer.reminder_permission }
  end
end
