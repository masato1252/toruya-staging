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

    # only the profile setting is finished
    if previous_controller_is("users/profiles")
      session[:settings_tour] = true
    end
  end

  def tour
    session[:settings_tour] = true
    redirect_to settings_user_menus_path(current_user)
  end

  def end_tour
    session.delete(:settings_tour)
    redirect_to settings_dashboard_path
  end
end
