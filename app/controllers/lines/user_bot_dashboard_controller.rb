require "user_bot_cookies"
require "liff_routing"

class Lines::UserBotDashboardController < ActionController::Base
  before_action :authenticate_current_user!
  layout "user_bot"

  include UserBotCookies

  def authenticate_current_user!
    unless current_user
      redirect_to LiffRouting.liff_url(:users_connect)
    end
  end

  def current_user
    @current_user ||= User.find_by(id: user_bot_cookies(:current_user_id))
  end
  helper_method :current_user
end
