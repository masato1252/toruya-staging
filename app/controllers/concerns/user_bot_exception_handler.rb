# frozen_string_literal: true

module UserBotExceptionHandler
  extend ActiveSupport::Concern

  included do
    rescue_from ActionController::RoutingError do
      redirect_to lines_user_bot_schedules_path, :alert => "This page does not exist."
    end

    rescue_from ActionController::InvalidAuthenticityToken do
      redirect_to lines_user_bot_schedules_path, :alert => "Invalid Request"
    end
  end
end
