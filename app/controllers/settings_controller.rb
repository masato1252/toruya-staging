# frozen_string_literal: true

class SettingsController < ActionController::Base
  abstract!

  layout "settings"

  include Authorization
  include AccountRequirement
  # XXX: It was suspended because of we didn't have any video or popup for the online booking tour, yet.
  # include BookingRequirement
  include ViewHelpers
  include Locale
  include ExceptionHandler

  before_action :authorize_manager_level_permission
  before_action :profile_required
  before_action :enable_tour_warning
  skip_before_action :track_ahoy_visit

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

  def authorize_manager_level_permission
    authorize! :manage, Settings
  end

  def from_line_bot
    false
  end
  helper_method :from_line_bot

  private

  def enable_tour_warning
    if request.query_parameters["enable_tour_warning"]
      session[:settings_tour] = true
    end
  end
end
