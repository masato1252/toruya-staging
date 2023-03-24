# frozen_string_literal: true

class Lines::UserBot::Customers::ReservationsController < Lines::UserBotDashboardController
  before_action :set_customer, only: [:index]

  def index
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
        year: relation.created_at.year,
        date: relation.created_at.to_s(:date),
        monthDate: I18n.l(relation.created_at, format: :month_day_wday),
        startTime: I18n.l(relation.created_at, format: :hour_minute),
        menu: relation.online_service.name,
        shop: relation.online_service.company.name,
        state: relation.state,
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
    render layout: false
  end

  def refund
    outcome = CustomerPayments::RefundReservation.run(
      reservation_customer: ReservationCustomer.find_by!(reservation_id: params[:reservation_id], customer_id: params[:customer_id]),
      amount: Money.new(params[:amount], Money.default_currency.iso_code)
    )

    if outcome.invalid?
      Rollbar.error(
        "Unexpected CustomerPayments::RefundReservation",
        errors: outcome.errors.details
      )
    end

    redirect_to lines_user_bot_customers_path(customer_id: params[:customer_id], reservation_id: params[:reservation_id], user_id: Current.business_owner.id, target_view: Customer::DASHBOARD_TARGET_VIEWS[:reservations])
  end

  private

  def set_customer
    @customer = Current.business_owner.customers.contact_groups_scope(current_user_staff).find(params[:customer_id])
  end
end
