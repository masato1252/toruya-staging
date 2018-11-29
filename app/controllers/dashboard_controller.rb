class DashboardController < ActionController::Base
  abstract!

  layout "application"
  include Authorization
  include ViewHelpers
  include Locale
  include ExceptionHandler
  include Sentry

  before_action :profile_required
  before_action :set_paper_trail_whodunnit
  before_action :checkin_user

  private

  def profile_required
    redirect_to new_profile_path unless current_user.profile
  end

  def contact_group_required
    redirect_to settings_dashboard_path unless BasicSettingsPresenter.new(super_user).customers_settings_completed?
  end

  def checkin_user
    Users::Access.run!(user: current_user) if current_user
  end
end
