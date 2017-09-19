class SettingsController < ActionController::Base
  layout "settings"

  include Authorization
  include AccountRequirement
  include ViewHelpers
  include Locale
  include Ssl
  include ExceptionHandler

  before_action :authorize_manager_level_permission

  def authorize_manager_level_permission
    authorize! :manage, Settings
  end
end
