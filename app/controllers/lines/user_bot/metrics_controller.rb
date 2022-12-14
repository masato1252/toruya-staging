# frozen_string_literal: true

class Lines::UserBot::MetricsController < Lines::UserBotDashboardController
  TOP_SERVICES_NUMBER = 10
  include ::MetricsHelpers

  def dashboard
    comparison_period = metric_start_time.advance(days: -30)..metric_start_time
    @active_customers_rate = (current_user.customers.active_in(1.year.ago).count / current_user.customers_count.to_f).round(3)

    @customers_count = current_user.customers.where("created_at > ?", metric_start_time).count
    @comparison_customers_count = @customers_count - current_user.customers.where(created_at: comparison_period).count

    @reservations_count = current_user.reservations.where("created_at > ?", metric_start_time).count
    @comparison_reservations_count = @reservations_count - current_user.reservations.where(created_at: comparison_period).count

    @customers_payment = CustomerPayment.completed.where(customer_id: current_user.customers.select(:id)).where("created_at > ?", metric_start_time).sum(:amount_cents).to_i
    @comparison_customers_payment = @customers_payment - CustomerPayment.completed.where(customer_id: current_user.customers.select(:id)).where(created_at: comparison_period).sum(:amount_cents).to_i
    @services_mapping_total_amount = ::Metrics::OnlineServicesRevenues.run!(user: current_user, metric_period: metric_period)

    if params[:demo]
      @active_customers_rate = (rand(100)/100.0).round(3)
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
    @online_services = current_user.online_services.order("updated_at DESC")
  end

  def online_service
  end
end
