# frozen_string_literal: true

class Settings::DashboardsController < ActionController::Base
  skip_before_action :track_ahoy_visit
  abstract!

  layout "settings"

  include Authorization
  include ViewHelpers
  include Locale
  include ExceptionHandler

  def index
    # only the profile setting is finished
    if previous_controller_is("users/profiles")
      session[:settings_tour] = true
    end
  end

  def tour
    session[:settings_tour] = true

    redirect_to basic_settings_presenter.last_step_task_path
  end

  def end_tour
    session.delete(:settings_tour)

    redirect_to member_path
  end

  def hide_tour_warning
    cookies[:basic_settings_tour_warning_hidden] = {
      value: true,
      expires: Time.current.advance(months: 1),
      domain: :all
    }

    redirect_to member_path
  end

  def booking_tour
    session[:booking_settings_tour] = true

    redirect_to booking_settings_presenter.last_step_task_path
  end

  def from_line_bot
    false
  end
  helper_method :from_line_bot
end
