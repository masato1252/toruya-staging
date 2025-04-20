# frozen_string_literal: true

class Lines::UserBot::Settings::RichMenusController < Lines::UserBotDashboardController
  def edit
    @social_account = Current.business_owner.social_account
    @current_rich_menu = Current.business_owner.social_account.current_rich_menu

    unless @current_rich_menu
      rich_menu_response = Current.business_owner.social_account.client.get_default_rich_menu
      # {"richMenuId"=>"richmenu-6899c82e5803cb4614bbd424697c4d36"}
      rich_menu_id = JSON.parse(rich_menu_response.body)["richMenuId"]

      if rich_menu_id && (social_rich_menu = SocialRichMenu.find_by(social_rich_menu_id: rich_menu_id))
        @current_rich_menu = RichMenus::SetCurrent.run(social_rich_menu: social_rich_menu)
        @current_rich_menu = social_rich_menu
      end

      if !rich_menu_id
        SocialAccounts::RichMenus::SwitchToOfficial.run(social_account: Current.business_owner.social_account)
        @current_rich_menu = Current.business_owner.social_account.current_rich_menu
      end
    end
  end

  def create
    # Switch back to toruya default
    SocialAccounts::RichMenus::SwitchBackToruya.run(social_account: Current.business_owner.social_account)

    redirect_to lines_user_bot_settings_social_account_social_rich_menus_path(business_owner_id: business_owner_id)
  end

  def destroy
    # turn off toruya default, using line official rich menu
    SocialAccounts::RichMenus::SwitchToOfficial.run(social_account: Current.business_owner.social_account)

    redirect_to lines_user_bot_settings_path(business_owner_id: business_owner_id)
  end
end
