class SettingsController < ActionController::Base
  layout "settings"
  before_action :authenticate_user!

  def super_user
    current_user
  end
  helper_method :super_user
end
