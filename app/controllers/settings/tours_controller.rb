# frozen_string_literal: true

class Settings::ToursController < ActionController::Base
  abstract!

  layout false

  include Authorization
  include ViewHelpers
  include Locale
  include ExceptionHandler
  include Sentry

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
end
