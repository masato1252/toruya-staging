# frozen_string_literal: true

class Lines::UserBot::BusinessOwnersController < Lines::UserBotDashboardController
  def update
    redirect_to lines_user_bot_settings_path(business_owner_id: params[:id])
  end
end
