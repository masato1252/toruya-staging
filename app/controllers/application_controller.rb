# frozen_string_literal: true

class ApplicationController < ActionController::Base
  skip_before_action :track_ahoy_visit

  layout "home"
  protect_from_forgery with: :exception, prepend: true
  before_action :authenticate_user!
  before_action :configure_permitted_parameters, if: :devise_controller?

  include ExceptionHandler

  private

  def configure_permitted_parameters
    # Or use this syntax
    # devise_parameter_sanitizer.permit(:sign_up, keys: [:name])
    devise_parameter_sanitizer.permit(:sign_up) { |u| u.permit(:name, :email, :password, :password_confirmation, :remember_me) }
    devise_parameter_sanitizer.permit(:sign_in) { |u| u.permit(:name, :email, :password, :remember_me) }
    devise_parameter_sanitizer.permit(:account_update) { |u| u.permit(:name, :email, :password, :password_confirmation, :current_password) }
  end

  def device_detector
    @device_detector ||=
      begin
        Current.device_detector = DeviceDetector.new(request.user_agent)
      end
  end
  helper_method :device_detector
end
