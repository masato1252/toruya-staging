class Lines::UserBot::Settings::ProfilesController < Lines::UserBotDashboardController
  before_action :set_profile, only: [:show, :edit, :update, :destroy]

  def show
    @profile = current_user.profile
  end
end
