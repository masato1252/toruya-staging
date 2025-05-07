# frozen_string_literal: true

class DashboardController < ActionController::Base
  abstract!

  layout "application"
  include Authorization
  include ViewHelpers
  include ParameterConverters
  include Locale
  include ExceptionHandler

  skip_before_action :track_ahoy_visit
  before_action :profile_required
  before_action :set_paper_trail_whodunnit

  def from_line_bot
    false
  end
  helper_method :from_line_bot

  private

  def profile_required
    unless current_user.profile
      # default is stay in personal dashboard
      cookies[:dashboard_mode] = {
        value: "user",
        domain: :all
      }
      redirect_to new_profile_path
    end
  end

  def contact_group_required
    redirect_to settings_dashboard_path unless Tours::BasicSettingsPresenter.new(view_context, super_user).customers_settings_completed?
  end

  def site_routing_helper
    @site_routing_helper ||= SiteRouting.new(view_context)
  end
  helper_method :site_routing_helper
end
