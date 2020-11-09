class Lines::UserBot::Settings::ProfilesController < Lines::UserBotDashboardController
  def show
    @profile = current_user.profile
  end

  def company
    @profile = current_user.profile
  end
end
