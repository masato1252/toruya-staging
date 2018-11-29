class DashboardController < ActionController::Base
  abstract!

  layout "application"
  include Authorization
  include ViewHelpers
  include Locale
  include ExceptionHandler
  include Sentry

  before_action :set_paper_trail_whodunnit
  before_action :checkin_user

  private

  def checkin_user
    Users::Access.run!(user: current_user) if current_user
  end
end
