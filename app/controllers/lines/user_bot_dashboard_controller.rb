require "user_bot_cookies"
require "liff_routing"

class Lines::UserBotDashboardController < ActionController::Base
  abstract!

  before_action :authenticate_current_user!
  layout "user_bot"

  include UserBotCookies
  include ViewHelpers

  def authenticate_current_user!
    unless current_user
      redirect_to LiffRouting.liff_url(:users_connect)
    end
  end

  def current_user
    @current_user ||= User.find_by(id: user_bot_cookies(:current_user_id))
  end
  helper_method :current_user
  alias_method :super_user, :current_user

  def social_user
    @social_user ||= SocialUser.find_by!(social_service_user_id: user_bot_cookies(:social_service_user_id))
  end
  helper_method :social_user

  def from_line_bot
    true
  end
  helper_method :from_line_bot
end
