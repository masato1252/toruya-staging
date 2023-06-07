# frozen_string_literal: true

class Lines::UserBot::BusinessOwnersController < Lines::UserBotDashboardController
  def index
    @owners = current_user.staff_accounts.active.includes(:owner).map(&:owner)
  end

  def update
    write_user_bot_cookies(:current_super_user_id, params[:id])
    if current_user&.id == 5 && params[:id].to_i == 2
      flash[:info] = "Business owner changing"
      Rollbar.error("Super user changed scenario4", request: request)
    end
    Rollbar.error("Super user changed scenario6", request: request) if current_user&.id == 5 && params[:id].to_i == 5

    redirect_to root_url
  end
end
