# frozen_string_literal: true

class Lines::UserBot::BusinessOwnersController < Lines::UserBotDashboardController
  def index
    @owners = current_user.staff_accounts.active.includes(:owner).map(&:owner)
  end

  def update
    write_user_bot_cookies(:current_super_user_id, params[:id])

    redirect_to root_url
  end
end
