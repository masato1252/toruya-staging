class Lines::UserBot::NotificationsController < Lines::UserBotDashboardController
  def index
    @messages = current_user.social_account.social_messages.includes(social_customer: :customer).unread

    if @messages.empty?
      UserBotLines::Actions::SwitchRichMenu.run(
        social_user: social_user,
        rich_menu_key: UserBotLines::RichMenus::Dashboard::KEY
      )
    end
  end
end
