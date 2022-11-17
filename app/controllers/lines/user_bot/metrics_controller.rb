# frozen_string_literal: true

class Lines::UserBot::MetricsController < Lines::UserBotDashboardController
  include ::MetricsHelpers

  def dashboard
    @active_customers_rate = current_user.customers.active_in(metric_start_time).count * 100 / current_user.customers_count
  end

  def sale_pages
  end

  def online_services
    @online_services = current_user.online_services.order("updated_at DESC")
  end

  def online_service
  end
end
