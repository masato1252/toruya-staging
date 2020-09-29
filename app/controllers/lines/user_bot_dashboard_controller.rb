require "user_bot_cookies"

class Lines::UserBotDashboardController < ActionController::Base
  include UserBotCookies

  def current_user
    @current_user ||= User.find(user_bot_cookies(:current_user_id))
  end
  helper_method :current_user
end
