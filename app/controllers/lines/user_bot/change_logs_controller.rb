class Lines::UserBot::ChangeLogsController < Lines::UserBotDashboardController
  skip_before_action :verify_authenticity_token

  def update
    SocialUser.where(social_service_user_id: Current.social_user.social_service_user_id).update_all(release_version: params[:release_version])

    head :ok
  end

  def show
    render json: {
      release_version: Current.social_user.release_version
    }
  end
end
