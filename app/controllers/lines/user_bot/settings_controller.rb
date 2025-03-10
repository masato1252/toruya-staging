# frozen_string_literal: true

class Lines::UserBot::SettingsController < Lines::UserBotDashboardController
  include ::MetricsHelpers

  def index
    @subscription = Current.business_owner.subscription
    @social_account = Current.business_owner.social_account

    comparison_period = metric_start_time.advance(days: -30)..metric_start_time
    @active_customers_rate = Current.business_owner.customers_count.positive? ? ((Current.business_owner.customers.active_in(1.year.ago).count / Current.business_owner.customers_count.to_f) * 100).to_i : 0

    @customers_count = Current.business_owner.customers.where(created_at: metric_period).count
    @comparison_customers_count = @customers_count - Current.business_owner.customers.where(created_at: comparison_period).count

    @reservations_count = Current.business_owner.reservations.where(created_at: metric_period).count
    @comparison_reservations_count = @reservations_count - Current.business_owner.reservations.where(created_at: comparison_period).count

    @services_mapping_total_amount = ::Metrics::OnlineServicesRevenues.run!(user: Current.business_owner, metric_period: metric_period)
    @booking_revenue = ::Metrics::BookingRevenue.run!(user: Current.business_owner, metric_period: metric_period)
    @customers_payment = @services_mapping_total_amount.sum { |service| service[:total_revenue] } + @booking_revenue.sum { |booking| booking["revenue"] }

    @comparison_services_mapping_total_amount = ::Metrics::OnlineServicesRevenues.run!(user: Current.business_owner, metric_period: comparison_period)
    @comparison_booking_revenue = ::Metrics::BookingRevenue.run!(user: Current.business_owner, metric_period: comparison_period)
    @comparison_customers_payment = @customers_payment - @comparison_services_mapping_total_amount.sum { |service| service[:total_revenue] } - @comparison_booking_revenue.sum { |booking| booking["revenue"] }

    if params[:staff_connect_result].present?
      params[:staff_connect_result] == 'true' ? flash.now[:success] = I18n.t("settings.staff_account.staff_connected_successfully") : flash.now[:alert] = I18n.t("settings.staff_account.staff_connected_failed")
    end

    if params[:consultant_connect_result].present?
      params[:consultant_connect_result] == 'true' ? flash.now[:success] = I18n.t("settings.consultant.consultant_connected_successfully") : flash.now[:alert] = I18n.t("settings.consultant.consultant_connected_failed")
    end
  end
end
