class Lines::Customers::DashboardsController < Lines::CustomersController
  include CompatSession
  skip_before_action :set_locale
  before_action :set_dashboard_locale

  def reservations
    context = compat_dashboard_context("reservations")
    if context
      @compat_dashboard = context
      render :reservations_compat
      return
    end

    upcoming_reservations = current_customer.reservations.future.uncanceled.pluck(:id)
    upcoming_reservation_customers = ReservationCustomer.where(reservation: upcoming_reservations, customer: current_customer).includes(:reservation).order("reservations.start_time": :desc).references(:reservations)
    past_reservations = current_customer.reservations.past.where(aasm_state: %w(pending reserved checked_in checked_out)).active.limit(20).pluck(:id)
    past_reservation_customers = ReservationCustomer.where(reservation: past_reservations, customer: current_customer).includes(:reservation).order("reservations.start_time": :desc).references(:reservations)

    @reservations = upcoming_reservations + past_reservations
    @reservation_customers = upcoming_reservation_customers + past_reservation_customers
  end

  def online_services
    context = compat_dashboard_context("online_services")
    if context
      @compat_dashboard = context
      render :online_services_compat
      return
    end

    online_service_relations = current_customer.online_service_customer_relations.includes(:online_service).order("online_service_customer_relations.id DESC")
    online_service_applications = current_customer.online_service_customer_applications.includes(:online_service).order("online_service_customer_relations.id DESC").limit(20)
    unavailable_online_service_relations = online_service_applications - online_service_relations
    @online_service_relations = online_service_relations + unavailable_online_service_relations
  end

  private

  def compat_dashboard_context(section)
    return nil unless compat_read_data_plane?

    customer_id =
      if params[:encrypted_customer_id].present?
        MessageEncryptor.decrypt(params[:encrypted_customer_id])
      else
        cookies[:verified_customer_id]
      end
    return nil if customer_id.blank?

    context = compat_fetch_v1_json(
      "/lines/customers/dashboard/#{params[:public_id]}/#{section}/page_context",
      customer_id: customer_id
    )&.dig("data")
    return nil unless context && compat_public_read_for_owner?(context["owner_user_id"])

    context
  end

  def set_dashboard_locale
    if compat_read_data_plane?
      I18n.locale = cookies[:locale].presence || I18n.default_locale
      Time.zone = ::LOCALE_TIME_ZONE[I18n.locale] || "Asia/Tokyo"
    else
      set_locale
    end
  end

  def current_owner
    @current_owner ||= User.find_by(public_id: params[:public_id])
  end
  helper_method :current_owner
end
