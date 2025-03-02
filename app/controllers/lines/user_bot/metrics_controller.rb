# frozen_string_literal: true

class Lines::UserBot::MetricsController < Lines::UserBotDashboardController
  TOP_SERVICES_NUMBER = 10
  include ::MetricsHelpers

  def dashboard
    comparison_period = metric_start_time.advance(days: -30)..metric_start_time
    @active_customers_rate = Current.business_owner.customers_count.positive? ? ((Current.business_owner.customers.active_in(1.year.ago).count / Current.business_owner.customers_count.to_f) * 100).to_i : 0

    @customers_count = Current.business_owner.customers.where("created_at > ?", metric_start_time).count
    @comparison_customers_count = @customers_count - Current.business_owner.customers.where(created_at: comparison_period).count

    @reservations_count = Current.business_owner.reservations.where("created_at > ?", metric_start_time).count
    @comparison_reservations_count = @reservations_count - Current.business_owner.reservations.where(created_at: comparison_period).count

    @customers_payment = CustomerPayment.completed.where(customer_id: Current.business_owner.customers.select(:id)).where("created_at > ?", metric_start_time).sum(:amount_cents).to_i
    @comparison_customers_payment = @customers_payment - CustomerPayment.completed.where(customer_id: Current.business_owner.customers.select(:id)).where(created_at: comparison_period).sum(:amount_cents).to_i
    @services_mapping_total_amount = ::Metrics::OnlineServicesRevenues.run!(user: Current.business_owner, metric_period: metric_period)
    @booking_revenue = ::Metrics::BookingRevenue.run!(user: Current.business_owner, metric_period: metric_period)


    if params[:demo]
      @active_customers_rate = ((rand(100)/100.0) * 100).to_i
      @customers_count = rand(100)
      @comparison_customers_count = rand(100)
      @reservations_count = rand(100)
      @comparison_reservations_count= -rand(100)
      @customers_payment = rand(100)
      @comparison_customers_payment= rand(100)
    end
  end

  def sale_pages
  end

  def online_services
    @online_services = Current.business_owner.online_services.order("updated_at DESC")
  end

  def booking_pages
    @booking_pages = Current.business_owner.booking_pages.order("updated_at DESC")
  end

  def booking_page
    @booking_page = Current.business_owner.booking_pages.find(params[:id])
  end

  def online_service
    @online_service = Current.business_owner.online_services.find(params[:id])
  end
end
