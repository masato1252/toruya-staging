# frozen_string_literal: true

class Lines::UserBot::BusinessOwnersController < Lines::UserBotDashboardController
  def update
    redirect_to lines_user_bot_metrics_dashboard_path(business_owner_id: params[:id])
  end
end
