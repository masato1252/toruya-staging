# frozen_string_literal: true

class Lines::UserBot::SettingsController < Lines::UserBotDashboardController
  def index
    @subscription = current_user.subscription
    @today_reservations_count = current_user.today_reservations_count
    @total_reservations_limit = "TOTAL_RESERVATIONS_LIMITS[current_user.permission_level]"
    @total_reservations_count = current_user.total_reservations_count
    @social_account = current_user.social_account
  end
end
