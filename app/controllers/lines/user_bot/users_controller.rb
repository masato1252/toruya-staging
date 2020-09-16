class Lines::UserBot::UsersController < Lines::UserBotController
  protect_from_forgery with: :exception, prepend: true

  def connect; end

  def sign_up; end
end
