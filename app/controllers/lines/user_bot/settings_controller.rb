# frozen_string_literal: true

class Lines::UserBot::SettingsController < Lines::UserBotDashboardController
  def index
    @subscription = current_user.subscription
    @total_customer_count = current_user.customers.count
    @total_customer_limit = Plan.max_customers_limit(current_user.current_plan.level, @subscription.rank) || I18n.t("settings.dashboard.no_limit")
    @total_sale_page_count = current_user.sale_pages.count
    @total_sale_page_limit = Plan.max_sale_pages_limit(current_user.current_plan.level, @subscription.rank) || I18n.t("settings.dashboard.no_limit")
    @social_account = current_user.social_account
  end
end
