module ExceptionHandler
  extend ActiveSupport::Concern

  included do
    rescue_from ActionController::RoutingError, ActiveRecord::RecordNotFound do
      redirect_to root_path, :alert => "This page does not exist."
    end

    rescue_from ActionController::InvalidAuthenticityToken do
      redirect_to root_path, :alert => "Invalid Request"
    end

    rescue_from CanCan::AccessDenied do |exception|
      redirect_to main_app.member_url, alert: I18n.t("common.no_permission")
    end
  end
end
