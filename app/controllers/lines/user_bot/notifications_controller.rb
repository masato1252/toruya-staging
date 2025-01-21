# frozen_string_literal: true

class Lines::UserBot::NotificationsController < Lines::UserBotDashboardController
  skip_before_action :redirect_from_rich_menu

  def index
    # Business
    @user_notifications = current_social_user.manage_accounts.map do |user|
      next unless user.social_account

      {
        user: user,
        messages: user.support_toruya_message_reply? ? user.social_account.social_messages.handleable.unread : [],
        reservations: user.pending_reservations || [],
        missing_sale_page_services: user.missing_sale_page_services || [],
        pending_customer_services: user.pending_customer_services || []
      }
    end.compact

    ::UserBotLines::Actions::SwitchRichMenu.run(social_user: current_social_user)
  end

  private

  def staff_ids
    @staff_ids ||= current_user.staff_accounts.active.pluck(:staff_id)
  end
end
