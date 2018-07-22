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

  def authorize_manager_level_permission
    authorize! :manage, Settings
  end
end
