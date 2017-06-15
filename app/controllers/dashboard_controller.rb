class DashboardController < ActionController::Base
  layout "application"
  protect_from_forgery with: :exception, prepend: true
  before_action :staff_requirement

  include ViewHelpers
  include Locale
  include Ssl

  rescue_from ActionController::RoutingError, ActiveRecord::RecordNotFound do
    redirect_to root_path, :alert => "This page does not exist."
  end

  def authorize_shop
    authorize! :read, shop
  end

  def staff_requirement
    unless staff
      redirect_to settings_path(current_user)
    end
  end
end
