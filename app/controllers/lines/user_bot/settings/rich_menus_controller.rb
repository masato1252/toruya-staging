# frozen_string_literal: true

class Lines::UserBot::Settings::RichMenusController < Lines::UserBotDashboardController
  def edit
    @social_account = Current.business_owner.social_account
    @current_rich_menu = Current.business_owner.social_account.social_rich_menus.current.take
  end

  def create
    # Switch back to toruya default
    SocialAccounts::RichMenus::SwitchBackToruya.run(social_account: Current.business_owner.social_account)

    redirect_to lines_user_bot_settings_path
  end

  def destroy
    # turn off toruya default, using line official rich menu
    SocialAccounts::RichMenus::SwitchToOfficial.run(social_account: Current.business_owner.social_account)

    redirect_to lines_user_bot_settings_path
  end
end
