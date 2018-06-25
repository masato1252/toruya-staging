class DashboardController < ActionController::Base
  abstract!

  layout "application"
  include Authorization
  include ViewHelpers
  include Locale
  include ExceptionHandler
  before_action :set_paper_trail_whodunnit
end
