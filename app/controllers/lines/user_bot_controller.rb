require "user_bot_cookies"

class Lines::UserBotController < ActionController::Base
  include UserBotCookies

  protect_from_forgery with: :exception, prepend: true
  layout "user_bot"
  attr_reader :social_user
  helper_method :social_user

  before_action :authenticate_social_user!

  def authenticate_social_user!
    if params[:social_service_user_id]
      social_service_user_id = params[:social_service_user_id].presence || user_bot_cookies(:social_service_user_id)
      write_user_bot_cookies(:social_service_user_id, social_service_user_id)
    end

    @social_user ||= SocialUser.find_by!(social_service_user_id: user_bot_cookies(:social_service_user_id))
  end

  def current_user
    @current_user ||= social_user.user
  end
  helper_method :current_user
end
