class DashboardController < ActionController::Base
  layout "application"
  protect_from_forgery with: :exception, prepend: true
  include Authorization
  include ViewHelpers
  include Locale
  include Ssl
  include ExceptionHandler

  before_action :staff_requirement

  def staff_requirement
    unless staff
      redirect_to settings_path(current_user)
    end
  end
end
