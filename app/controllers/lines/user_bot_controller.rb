# frozen_string_literal: true

require "user_bot_cookies"

class Lines::UserBotController < ActionController::Base
  include UserBotCookies

  protect_from_forgery with: :exception, prepend: true
  layout "user_bot_guest"
  attr_reader :social_user
  helper_method :social_user

  before_action :authenticate_social_user!
  skip_before_action :track_ahoy_visit

  def authenticate_social_user!
    if params[:social_service_user_id]
      social_service_user_id = params[:social_service_user_id].presence || user_bot_cookies(:social_service_user_id)
      write_user_bot_cookies(:social_service_user_id, social_service_user_id)
    end

    @social_user ||= SocialUser.find_by!(social_service_user_id: user_bot_cookies(:social_service_user_id))
  end

  def current_user
    # XXX: for security, one the user pass the phone number identification able to set the current_user_id,
    # So even the line user id was stolen, it still useless for our main feature, they only could access
    # the guest feature(sign in or sign up)
    @current_user ||= User.find_by(id: user_bot_cookies(:current_user_id))

    if @current_user && social_user.user && @current_user.id != social_user.user_id
      Rollbar.warning(
        "Unmatch user id from user bot",
        params: {
          social_service_user_id: @social_user.social_service_user_id,
          user_id: @current_user&.id,
          social_user_user_id: social_user.user_id
        }
      )
    end

    @current_user
  end
  helper_method :current_user
end
