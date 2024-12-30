# frozen_string_literal: true

class Lines::UserBot::SettingsController < Lines::UserBotDashboardController
  include ::MetricsHelpers

  def index
    @subscription = Current.business_owner.subscription
    @total_customer_count = Current.business_owner.customers.count
    @total_customer_limit = Plan.max_customers_limit(Current.business_owner.current_plan.level, @subscription.rank) || I18n.t("settings.dashboard.no_limit")
    @social_account = Current.business_owner.social_account
    @customers_payment = CustomerPayment.completed.where(customer_id: Current.business_owner.customers.select(:id)).where("created_at > ?", metric_start_time).sum(:amount_cents).to_i

    if params[:staff_connect_result].present?
      params[:staff_connect_result] == 'true' ? flash.now[:success] = I18n.t("settings.staff_account.staff_connected_successfully") : flash.now[:alert] = I18n.t("settings.staff_account.staff_connected_failed")
    end

    if params[:consultant_connect_result].present?
      params[:consultant_connect_result] == 'true' ? flash.now[:success] = I18n.t("settings.consultant.consultant_connected_successfully") : flash.now[:alert] = I18n.t("settings.consultant.consultant_connected_failed")
    end
  end
end
