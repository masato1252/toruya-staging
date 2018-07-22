class DashboardController < ActionController::Base
  abstract!

  layout "application"
  include Authorization
  include ViewHelpers
  include Locale
  include ExceptionHandler
  include Sentry
end
