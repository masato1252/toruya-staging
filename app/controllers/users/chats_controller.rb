class Users::ChatsController < DashboardController
  def index
    @social_accounts = super_user.social_accounts
  end
end
