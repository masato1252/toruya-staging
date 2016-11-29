class DashboardController < ActionController::Base
  layout "application"
  protect_from_forgery with: :exception, prepend: true

  include AccountRequirement
  include ViewHelpers
  include Locale

  rescue_from ActionController::RoutingError, ActiveRecord::RecordNotFound do
    redirect_to root_path, :alert => "This page does not exist."
  end
end
