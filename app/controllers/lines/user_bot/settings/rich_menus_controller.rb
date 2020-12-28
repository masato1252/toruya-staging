class Lines::UserBot::Settings::RichMenusController < Lines::UserBotDashboardController
  def edit
    @social_account = current_user.social_account
  end

  def create
    # Switch back to toruya default
    SocialAccounts::RichMenus::SwitchBackToruya.run(social_account: current_user.social_account)

    redirect_to lines_user_bot_settings_path
  end

  def destroy
    # turn off toruya default, using line official rich menu
    SocialAccounts::RichMenus::SwitchToOfficial.run(social_account: current_user.social_account)

    redirect_to lines_user_bot_settings_path
  end
end
