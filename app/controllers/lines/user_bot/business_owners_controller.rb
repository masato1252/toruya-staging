# frozen_string_literal: true

class Lines::UserBot::BusinessOwnersController < Lines::UserBotDashboardController
  def index
    @owners = current_user.staff_accounts.active.includes(:owner).map(&:owner)
  end

  def update
    redirect_to lines_user_bot_metrics_dashboard_path(business_owner_id: params[:id])
  end
end
