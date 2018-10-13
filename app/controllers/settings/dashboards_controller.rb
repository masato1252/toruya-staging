class Settings::DashboardsController < ActionController::Base
  abstract!

  layout "settings"

  include Authorization
  include ViewHelpers
  include Locale
  include ExceptionHandler
  include Sentry

  def index
    @subscription = current_user.subscription
    @today_reservations_count = current_user.today_reservations_count
    @total_reservations_limit = Reservations::TotalLimit::TOTAL_RESERVATIONS_LIMITS[current_user.member_level]
    @total_reservations_count = current_user.total_reservations_count
  end
end
