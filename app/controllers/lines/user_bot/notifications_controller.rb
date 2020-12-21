class Lines::UserBot::NotificationsController < Lines::UserBotDashboardController
  def index
    @messages = current_user.social_account.social_messages.includes(social_customer: :customer).unread
  end
end
