# frozen_string_literal: true

require "line_client"

class UserBotLines::Actions::SwitchRichMenu < ActiveInteraction::Base
  object :social_user
  string :rich_menu_key, default: UserBotLines::RichMenus::Dashboard::KEY

  def execute
    menu_key = nil

    if rich_menu_key == UserBotLines::RichMenus::Dashboard::KEY
      social_user.manage_accounts.each do |owner|
        if (unread_messages_exists?(owner) ||
            owner.pending_reservations.exists? ||
            owner.pending_customer_services.exists?)
          menu_key = UserBotLines::RichMenus::DashboardWithNotifications::KEY
        end
      end
    end

    menu_key ||= rich_menu_key

    if social_user.social_rich_menu_key != menu_key && !Rails.env.development?
      social_rich_menu = ::SocialRichMenu.find_by(social_name: menu_key, locale: social_user.locale)
      
      if social_rich_menu
        compose(
          ::RichMenus::Connect,
          social_target: social_user,
          social_rich_menu: social_rich_menu
        )
      else
        Rails.logger.warn("[SwitchRichMenu] SocialRichMenu not found: social_name=#{menu_key}, locale=#{social_user.locale}")
      end
    end
  end

  private

  def unread_messages_exists?(owner)
    owner.social_account && owner.social_account.social_messages.handleable.unread.exists?
  end
end
