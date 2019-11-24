class SettingsController < ActionController::Base
  abstract!

  layout "settings"

  include Authorization
  include AccountRequirement
  include BookingRequirement
  include ViewHelpers
  include Locale
  include ExceptionHandler
  include Sentry

  before_action :authorize_manager_level_permission
  before_action :profile_required
  before_action :enable_tour_warning

  def profile_required
    unless current_user.profile
      # default is stay in personal dashboard
      cookies[:dashboard_mode] = "user"
      redirect_to new_profile_path
    end
  end

  def authorize_manager_level_permission
    authorize! :manage, Settings
  end

  private

  def enable_tour_warning
    if request.query_parameters["enable_tour_warning"]
      session[:settings_tour] = true
    end
  end
end
