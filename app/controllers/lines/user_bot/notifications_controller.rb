# frozen_string_literal: true

class Lines::UserBot::NotificationsController < Lines::UserBotDashboardController
  def index
    @messages = current_user.social_account.social_messages.handleable.unread
    @reservations = current_user.pending_reservations
    @services = current_user.missing_sale_page_services

    if @messages.empty? || @reservations.empty? || @services.empty?
      UserBotLines::Actions::SwitchRichMenu.run(
        social_user: social_user,
        rich_menu_key: UserBotLines::RichMenus::Dashboard::KEY
      )
    end
  end

  private

  def staff_ids
    @staff_ids ||= current_user.staff_accounts.active.pluck(:staff_id)
  end
end
