# frozen_string_literal: true

class Lines::UserBot::BusinessOwnersController < Lines::UserBotDashboardController
  def update
    if account = current_user.current_staff_account(User.find(params[:id]))
      if account.owner?
        write_user_bot_cookies(:current_user_id, account.owner_id)
      end

      redirect_to lines_user_bot_metrics_dashboard_path(business_owner_id: params[:id])
    end
  end
end
