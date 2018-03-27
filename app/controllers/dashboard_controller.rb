class DashboardController < ActionController::Base
  layout "application"
  include Authorization
  include ViewHelpers
  include Locale
  include ExceptionHandler
end
