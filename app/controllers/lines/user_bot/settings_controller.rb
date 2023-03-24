# frozen_string_literal: true

class Lines::UserBot::SettingsController < Lines::UserBotDashboardController
  include ::MetricsHelpers

  def index
    @subscription = Current.business_owner.subscription
    @total_customer_count = Current.business_owner.customers.count
    @total_customer_limit = Plan.max_customers_limit(Current.business_owner.current_plan.level, @subscription.rank) || I18n.t("settings.dashboard.no_limit")
    @total_sale_page_count = Current.business_owner.sale_pages.count
    @total_sale_page_limit = Plan.max_sale_pages_limit(Current.business_owner.current_plan.level, @subscription.rank) || I18n.t("settings.dashboard.no_limit")
    @social_account = Current.business_owner.social_account
    @customers_payment = CustomerPayment.completed.where(customer_id: Current.business_owner.customers.select(:id)).where("created_at > ?", metric_start_time).sum(:amount_cents).to_i
  end
end
