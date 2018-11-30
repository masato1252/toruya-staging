class DashboardController < ActionController::Base
  abstract!

  layout "application"
  include Authorization
  include ViewHelpers
  include Locale
  include ExceptionHandler
  include Sentry

  before_action :set_paper_trail_whodunnit
  before_action :sync_user

  private

  def sync_user
    Users::ContactsSync.run!(user: super_user) if super_user
  end
end
