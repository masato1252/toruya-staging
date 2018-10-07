class DashboardController < ActionController::Base
  abstract!

  layout "application"
  include Authorization
  include ViewHelpers
  include Locale
  include ExceptionHandler
  include Sentry

  before_action :set_paper_trail_whodunnit

  private

  def profile_required
    redirect_to settings_path(current_user) unless super_user.profile
  end

  def contact_group_required
    redirect_to settings_path(current_user) unless super_user.contact_groups.connected.exists?
  end
end
