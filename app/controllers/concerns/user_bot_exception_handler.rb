module UserBotExceptionHandler
  extend ActiveSupport::Concern

  included do
    rescue_from ActionController::RoutingError, ActiveRecord::RecordNotFound do
      redirect_to lines_user_bot_schedules_path, :alert => "This page does not exist."
    end

    rescue_from ActionController::InvalidAuthenticityToken do
      redirect_to lines_user_bot_schedules_path, :alert => "Invalid Request"
    end

    rescue_from CanCan::AccessDenied do |exception|
      redirect_to main_app.lines_user_bot_schedules_url, alert: I18n.t("common.no_permission")
    end
  end
end
