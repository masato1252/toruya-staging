# frozen_string_literal: true

class Lines::UserBot::Customers::ReservationsController < Lines::UserBotDashboardController
  include CrossAccountRedirect
  redirect_to_correct_owner_for :customers, param_key: :customer_id

  before_action :set_customer, only: [:index]

  def index
    if compat_read_enabled?
      owner_id = resolve_compat_owner_id(nil) || resolve_compat_current_user_id(nil)
      payload = owner_id && compat_fetch_v1_json(
        "/lines/user_bot/owner/#{owner_id}/customer/reservations",
        { customer_id: params[:customer_id] }
      )

      if payload
        render json: payload
      else
        render json: { status: "failed", error_message: "利用履歴の取得に失敗しました" }, status: :bad_gateway
      end
      return
    end

    head :unprocessable_entity if cannot?(:read, @customer)

    reservation_customers =
      @customer.reservation_customers
        .includes(reservation: [ :menus, :active_reservation_customers, :reservation_menus, :customers, :staffs, shop: :user, reservation_staffs: [ :menu, :staff ] ])
        .merge(Reservation.active)
        .order("reservations.start_time DESC")

    relations = @customer.online_service_customer_applications.includes(:online_service).map do |relation|
      {
        type: 'OnlineServiceCustomerRelation',
        id: relation.id,
        userId: relation.online_service.user_id,
        year: relation.created_at.year,
        date: relation.created_at.to_fs(:date),
        monthDate: I18n.l(relation.created_at, format: :month_day_wday),
        startTime: I18n.l(relation.created_at, format: :hour_minute),
        menu: relation.online_service.name,
        shop: relation.online_service.user.shops.first&.name || relation.online_service.company&.company_name,
        state: relation.state,
        reservation_customer_state: relation.state,
        "time" => relation.created_at.to_i
      }
    end

    reservations = view_context.reservation_customer_options(reservation_customers)
    #XXX: reservations keys were String
    reservations.concat(relations).sort_by! { |option| option["time"] }.reverse!

    render json: {
      reservations: reservations
    }
  end

  def accept
    return compat_reservation_customer_transition("accept") if compat_read_data_plane?

    outcome = ReservationCustomers::Accept.run(reservation_id: params[:reservation_id], customer_id: params[:customer_id], current_staff: current_user_staff)

    if outcome.invalid?
      Rollbar.error(
        "Unexpected ReservationCustomers::Accept",
        errors: outcome.errors.details
      )
    end

    redirect_back fallback_location: SiteRouting.new(view_context).customers_path(Current.business_owner.id, customer_id: params[:customer_id])
  end

  def pend
    return compat_reservation_customer_transition("pend") if compat_read_data_plane?

    outcome = ReservationCustomers::Pend.run(reservation_id: params[:reservation_id], customer_id: params[:customer_id])

    if outcome.invalid?
      Rollbar.error(
        "Unexpected ReservationCustomers::Pend",
        errors: outcome.errors.details
      )
    end

    redirect_back fallback_location: SiteRouting.new(view_context).customers_path(Current.business_owner.id, customer_id: params[:customer_id])
  end

  def cancel
    return compat_reservation_customer_transition("cancel") if compat_read_data_plane?

    outcome = ReservationCustomers::Cancel.run(reservation_id: params[:reservation_id], customer_id: params[:customer_id])

    if outcome.invalid?
      Rollbar.error(
        "Unexpected ReservationCustomers::Cancel",
        errors: outcome.errors.details
      )
    end

    redirect_back fallback_location: SiteRouting.new(view_context).customers_path(Current.business_owner.id, customer_id: params[:customer_id])
  end

  def refund_modal
    @reservation_customer = ReservationCustomer.find_by!(reservation_id: params[:reservation_id], customer_id: params[:customer_id])
    @paid_payment = @reservation_customer.paid_payment
    render layout: false
  end

  def compat_reservation_customer_transition(action)
    owner_id = resolve_compat_owner_id(nil) || resolve_compat_current_user_id(nil)
    result = compat_v1_post(
      "/lines/user_bot/owner/#{owner_id}/customer/reservations/#{params[:reservation_id]}/#{action}/#{params[:customer_id]}",
      { current_user_id: resolve_compat_current_user_id(nil) }
    )
    flash[:alert] = I18n.t("common.operation_failed", default: "更新に失敗しました") unless result&.dig("status") == "successful"
    redirect_back fallback_location: SiteRouting.new(view_context).customers_path(owner_id, customer_id: params[:customer_id])
  end

  def refund
    if compat_read_data_plane?
      owner_id = resolve_compat_owner_id(nil) || resolve_compat_current_user_id(nil)
      result = compat_v1_post(
        "/lines/user_bot/owner/#{owner_id}/customer/reservations/#{params[:reservation_id]}/refund/#{params[:customer_id]}",
        { amount: params[:amount] }
      )
      failure_path = lines_user_bot_customers_path(
        business_owner_id: owner_id,
        customer_id: params[:customer_id],
        reservation_id: params[:reservation_id],
        user_id: owner_id,
        target_view: Customer::DASHBOARD_TARGET_VIEWS[:reservations]
      )
      success_path = lines_user_bot_customers_path(
        business_owner_id: owner_id,
        customer_id: params[:customer_id],
        reservation_id: params[:reservation_id],
        user_id: owner_id,
        target_view: Customer::DASHBOARD_TARGET_VIEWS[:payments]
      )

      if result&.dig("status") == "successful"
        redirect_to success_path
      else
        redirect_to failure_path, alert: I18n.t("common.operation_failed", default: "返金に失敗しました")
      end
      return
    end

    reservation_customer = ReservationCustomer.find_by!(reservation_id: params[:reservation_id], customer_id: params[:customer_id])
    customer = reservation_customer.customer
    paid_payment = customer.customer_payments.completed.where(product: reservation_customer).first

    if paid_payment
      outcome = CustomerPayments::Refund.run(
        customer_payment: paid_payment,
        amount: Money.new(params[:amount], paid_payment.amount_currency)
      )

      if outcome.invalid?
        Rollbar.error(
          "Unexpected CustomerPayments::Refund",
          errors: outcome.errors.details
        )
        redirect_to lines_user_bot_customers_path(business_owner_id: Current.business_owner.id, customer_id: params[:customer_id], reservation_id: params[:reservation_id], user_id: Current.business_owner.id, target_view: Customer::DASHBOARD_TARGET_VIEWS[:reservations]), alert: outcome.errors.full_messages.to_sentence
      else
        redirect_to lines_user_bot_customers_path(customer_id: params[:customer_id], reservation_id: params[:reservation_id], user_id: Current.business_owner.id, target_view: Customer::DASHBOARD_TARGET_VIEWS[:payments])
      end
    else
      redirect_to lines_user_bot_customers_path(customer_id: params[:customer_id], reservation_id: params[:reservation_id], user_id: Current.business_owner.id, target_view: Customer::DASHBOARD_TARGET_VIEWS[:reservations]), alert: I18n.t("common.not_paid_payment")
    end
  end

  def edit_ticket_modal
    @reservation_customer = ReservationCustomer.find_by!(reservation_id: params[:reservation_id], customer_id: params[:customer_id])
    render layout: false
  end

  def update_ticket
    reservation_customer = ReservationCustomer.find_by!(reservation_id: params[:reservation_id], customer_id: params[:customer_id])
    outcome = CustomerTickets::Update.run(customer_ticket: reservation_customer.customer_tickets.find(params[:customer_ticket_id]), expire_at: params[:expire_at])

    if outcome.invalid?
      Rollbar.error(
        "Unexpected CustomerTickets::Update",
        errors: outcome.errors.details
      )
    end

    redirect_to lines_user_bot_customers_path(business_owner_id: reservation_customer.reservation.user_id, customer_id: params[:customer_id], reservation_id: params[:reservation_id], user_id: Current.business_owner.id, target_view: Customer::DASHBOARD_TARGET_VIEWS[:reservations])
  end

  private

  def set_customer
    if compat_read_enabled?
      return
    end

    @customer = Current.business_owner.customers.contact_groups_scope(current_user_staff).find(params[:customer_id])
  end
end
