require "liff_routing"

class Lines::UserBot::UsersController < Lines::UserBotController
  protect_from_forgery with: :exception, prepend: true

  def connect
    @liff_id = LiffRouting::LIFF_ID
  end

  def sign_up
  end
end
