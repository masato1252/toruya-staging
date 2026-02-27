# frozen_string_literal: true

require "slack_error_notifier"

class SlackErrorMiddleware
  IGNORED_PATHS = %w[
    /health
    /favicon.ico
    /robots.txt
    /assets/
    /packs/
  ].freeze

  def initialize(app)
    @app = app
  end

  def call(env)
    begin
      status, headers, response = @app.call(env)
    rescue StandardError => e
      notify_exception(e, env)
      raise
    end

    if status >= 500
      notify_status_error(status, env)
    end

    [status, headers, response]
  end

  private

  def notify_exception(exception, env)
    return if ignored_path?(env)

    context = build_context(env).merge(source: "Middleware (uncaught exception)")
    SlackErrorNotifier.notify(exception, context)
  end

  def notify_status_error(status, env)
    return if ignored_path?(env)

    error = StandardError.new("HTTP #{status} - #{env["REQUEST_METHOD"]} #{env["REQUEST_PATH"] || env["PATH_INFO"]}")
    error.set_backtrace([])
    context = build_context(env).merge(source: "Middleware (#{status} response)")
    SlackErrorNotifier.notify(error, context)
  end

  def build_context(env)
    request = ActionDispatch::Request.new(env) rescue nil
    ctx = {
      request_method: env["REQUEST_METHOD"],
      request_path: env["REQUEST_PATH"] || env["PATH_INFO"],
      remote_ip: request&.remote_ip || env["REMOTE_ADDR"]
    }
    if (user = env["warden"]&.user rescue nil)
      ctx[:user_id] = user.id
    end
    ctx
  end

  def ignored_path?(env)
    path = env["PATH_INFO"].to_s
    IGNORED_PATHS.any? { |ignored| path.start_with?(ignored) }
  end
end
