class DashboardController < ActionController::Base
  abstract!

  layout "application"
  include Authorization
  include ViewHelpers
  include ParameterConverters
  include Locale
  include ExceptionHandler
  include Sentry

  before_action :profile_required
  before_action :set_paper_trail_whodunnit
  before_action :sync_user

  def from_line_bot
    false
  end
  helper_method :from_line_bot

  private

  def profile_required
    unless current_user.profile
      # default is stay in personal dashboard
      cookies[:dashboard_mode] = "user"
      redirect_to new_profile_path
    end
  end

  def contact_group_required
    redirect_to settings_dashboard_path unless Tours::BasicSettingsPresenter.new(view_context, super_user).customers_settings_completed?
  end

  def sync_user
    Users::ContactsSync.run!(user: super_user) if super_user
  end

  def site_routing_helper
    @site_routing_helper ||= SiteRouting.new(view_context)
  end
  helper_method :site_routing_helper
end
