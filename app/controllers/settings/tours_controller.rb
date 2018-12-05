class Settings::ToursController < ActionController::Base
  abstract!

  layout false

  include Authorization
  include ViewHelpers
  include Locale
  include ExceptionHandler
  include Sentry

  def current_step
    @from_settings_tour_root = true
    render basic_setting_presenter.current_step
  end

  def welcome; end
  def contact_group; end
  def shop; end
  def business_schedule; end
  def working_time; end
  def reservation_setting; end
  def menu; end
end
