# frozen_string_literal: true

# OmniAuth 1.9.x の call! メソッドには rescue ブロックがないため、
# before_request_phase (omniauth-rails_csrf_protection) で発生する
# ActionController::InvalidAuthenticityToken がそのまま伝播し、
# ActionDispatch::ShowExceptions が public/422.html を返してしまう。
#
# このミドルウェアで OmniAuth ストラテジーを包み、
# CSRF 検証失敗時にはリファラー（予約ページ等）にリダイレクトする。
class OmniauthCsrfRescue
  def initialize(app)
    @app = app
  end

  def call(env)
    @app.call(env)
  rescue ActionController::InvalidAuthenticityToken => e
    request = ActionDispatch::Request.new(env)

    unless omniauth_request_phase?(request)
      raise
    end

    redirect_url = request.referer || "/"

    Rails.logger.warn(
      "[OmniauthCsrfRescue] CSRF verification failed for #{request.request_method} #{request.path}. " \
      "Redirecting to #{redirect_url}. " \
      "Session has _csrf_token: #{request.session.to_h.key?('_csrf_token')}, " \
      "authenticity_token param present: #{request.params['authenticity_token'].present?}"
    )

    if defined?(Rollbar)
      Rollbar.warn("OmniAuth CSRF verification failed", {
        path: request.path,
        method: request.request_method,
        referer: request.referer,
        session_has_csrf: request.session.to_h.key?("_csrf_token"),
        token_param_present: request.params["authenticity_token"].present?
      })
    end

    [302, { "Location" => redirect_url, "Content-Type" => "text/html" }, []]
  end

  private

  OMNIAUTH_PATH_PREFIX = "/users/auth/"

  def omniauth_request_phase?(request)
    path = request.path
    path.start_with?(OMNIAUTH_PATH_PREFIX) && !path.include?("/callback")
  end
end
