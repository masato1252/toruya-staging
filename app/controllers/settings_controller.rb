class SettingsController < ActionController::Base
  abstract!

  layout "settings"

  include Authorization
  include AccountRequirement
  include ViewHelpers
  include Locale
  include ExceptionHandler
  include Sentry

  before_action :authorize_manager_level_permission
  before_action :profile_required

  def profile_required
    redirect_to new_profile_path unless current_user.profile
  end

  def authorize_manager_level_permission
    authorize! :manage, Settings
  end
end
