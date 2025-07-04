# frozen_string_literal: true

require "user_bot_cookies"

class Lines::UserBotController < ActionController::Base
  include UserBotCookies

  protect_from_forgery with: :exception, prepend: true
  layout "user_bot_guest"
  attr_reader :social_user
  helper_method :social_user
  alias_method :current_social_user, :social_user

  before_action :authenticate_social_user!
  skip_before_action :track_ahoy_visit
  before_action :set_locale

  def authenticate_social_user!
    if params[:social_service_user_id]
      social_service_user_id = params[:social_service_user_id].presence || user_bot_cookies(:social_service_user_id)
      write_user_bot_cookies(:social_service_user_id, social_service_user_id)
    end

    @social_user ||= SocialUser.where.not(user_id: nil).find_by(social_service_user_id: user_bot_cookies(:social_service_user_id)) || SocialUser.find_by(social_service_user_id: user_bot_cookies(:social_service_user_id))
  end

  def current_users
    social_user.current_users
  end
  helper_method :current_users

  def current_user
    # XXX: for security, one the user pass the phone number identification able to set the current_user_id,
    # So even the line user id was stolen, it still useless for our main feature, they only could access
    # the guest feature(sign in or sign up)
    @current_user ||= User.find_by(id: user_bot_cookies(:current_user_id))
    @current_user ||= social_user&.root_user
  end
  helper_method :current_user

  def set_locale
    I18n.locale = params[:locale].presence || current_social_user&.locale || cookies[:locale] || I18n.default_locale
    cookies.clear_across_domains(:locale)
    cookies.set_across_domains(:locale, I18n.locale, expires: 20.years.from_now)
    Time.zone = ::LOCALE_TIME_ZONE[I18n.locale] || "Asia/Tokyo"
  end

  def device_detector
    @device_detector ||=
      begin
        Current.device_detector = DeviceDetector.new(request.user_agent)
      end
  end
  helper_method :device_detector
end