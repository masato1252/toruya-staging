# frozen_string_literal: true

class Lines::UserBot::SettingsController < Lines::UserBotDashboardController
  def index
    @subscription = current_user.subscription
    @total_customer_count = current_user.customers.count
    @total_customer_limit = Ability::CUSTOMER_LIMIT[current_user.current_plan.level] || I18n.t("settings.dashboard.no_limit")
    @total_sale_page_count = current_user.sale_pages.count
    @total_sale_page_limit = Ability::SALE_PAGE_LIMIT[current_user.current_plan.level] || I18n.t("settings.dashboard.no_limit")
    @social_account = current_user.social_account
  end
end
