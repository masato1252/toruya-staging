module ExceptionHandler
  extend ActiveSupport::Concern

  included do
    rescue_from ActionController::RoutingError, ActiveRecord::RecordNotFound do
      redirect_to root_path, :alert => "This page does not exist."
    end

    rescue_from CanCan::AccessDenied do |exception|
      redirect_to main_app.root_url, alert: "No permission"
    end
  end
end
