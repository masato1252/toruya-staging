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
        userId: relation.online_service.user_id,
        year: relation.created_at.year,
        date: relation.created_at.to_fs(:date),
        monthDate: I18n.l(relation.created_at, format: :month_day_wday),
        startTime: I18n.l(relation.created_at, format: :hour_minute),
        menu: relation.online_service.name,
        shop: relation.online_service.company.company_name,
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
    @paid_payment = @reservation_customer.paid_payment
    render layout: false
  end

  def refund
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
    @customer = Current.business_owner.customers.contact_groups_scope(current_user_staff).find(params[:customer_id])
  end
end
