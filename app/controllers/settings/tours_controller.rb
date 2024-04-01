# frozen_string_literal: true

class Settings::ToursController < ActionController::Base
  skip_before_action :track_ahoy_visit
  abstract!

  layout false

  include Authorization
  include ViewHelpers
  include Locale
  include ExceptionHandler

  def current_step_warning
    @from_settings_tour_root = true
    render basic_settings_presenter.current_step_warning
  end

  def welcome; end
  def contact_group; end
  def shop; end
  def business_schedule; end
  def working_time; end
  def reservation_setting; end
  def menu; end

  def from_line_bot
    false
  end
  helper_method :from_line_bot
end
