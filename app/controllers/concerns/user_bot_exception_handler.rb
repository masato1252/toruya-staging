# frozen_string_literal: true

require "slack_error_notifier"

module UserBotExceptionHandler
  extend ActiveSupport::Concern

  included do
    rescue_from ActionController::RoutingError do
      redirect_to lines_user_bot_schedules_path, :alert => "This page does not exist."
    end

    rescue_from ActionController::InvalidAuthenticityToken do
      redirect_to lines_user_bot_schedules_path, :alert => "Invalid Request"
    end

    rescue_from ActiveRecord::RecordNotFound do
      redirect_to lines_user_bot_schedules_path(business_owner_id: business_owner_id),
                  alert: I18n.t("common.record_not_found", default: "このページは見つかりませんでした。アカウントを確認してください。")
    end

    rescue_from StandardError do |exception|
      SlackErrorNotifier.notify(exception, slack_error_context)
      Rollbar.error(exception) if defined?(Rollbar)
      raise exception
    end
  end

  private

  def slack_error_context
    ctx = {
      source: "UserBotController",
      request_method: request.method,
      request_path: request.fullpath,
      remote_ip: request.remote_ip
    }
    ctx[:user_id] = current_user.id if current_user rescue nil
    ctx
  end
end
