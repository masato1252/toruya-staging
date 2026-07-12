# frozen_string_literal: true

class Lines::UserBot::SettingsController < Lines::UserBotDashboardController
  include ::MetricsHelpers

  def index
    if compat_read_enabled?
      apply_compat_settings_index!
      return
    end

    @subscription = Current.business_owner.subscription
    @social_account = Current.business_owner.social_account
    @total_customer_count = Current.business_owner.customers.count
    @total_customer_limit = Plan.max_customers_limit(Current.business_owner.current_plan.level, @subscription.rank) || I18n.t("settings.dashboard.no_limit")

    @days_in_period = (metric_period.end.to_date - metric_period.begin.to_date).to_i
    comparison_period = metric_start_time.advance(days: -@days_in_period)..metric_start_time
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

  private

  def apply_compat_settings_index!
    form = compat_fetch_v1_json(
      "/lines/user_bot/owner/#{business_owner_id}/settings/page_context"
    )&.dig("data", "edit_form")

    @subscription = Current.business_owner.subscription
    @social_account = Current.business_owner.social_account
    @days_in_period = form&.dig("days_in_period").presence || 30
    @active_customers_rate = 0
    @customers_count = 0
    @comparison_customers_count = 0
    @reservations_count = 0
    @comparison_reservations_count = 0
    @comparison_customers_payment = 0

    @total_customer_count = form&.dig("total_customer_count").to_i
    limit = form&.dig("total_customer_limit")
    @total_customer_limit =
      if form.nil?
        I18n.t("settings.dashboard.no_limit")
      elsif limit.nil?
        I18n.t("settings.dashboard.no_limit")
      else
        limit
      end
    @customers_payment = form&.dig("customers_payment").to_i

    @compat_settings = form
    return if form.blank?

    @member_plan_name = form["member_plan_name"]
    @subscription_status_label = form["subscription_status"]
    @subscription_active = form["subscription_active"] == true
    @charge_required = form["charge_required"] == true
    @expired_date_label = form["expired_date"]
    @next_plan_name = form["next_plan_name"]
    @team_plan_member = form["team_plan_member"] == true
    @has_single_shop = form["has_single_shop"] == true
    @first_shop_id = form["first_shop_id"]
    @line_settings_verified = form["line_settings_verified"] == true
    @using_line_official_account = form["using_line_official_account"] == true
  end
end
