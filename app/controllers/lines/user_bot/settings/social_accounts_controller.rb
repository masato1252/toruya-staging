class Lines::UserBot::Settings::SocialAccountsController < Lines::UserBotDashboardController
  def show
    @social_account = current_user.social_account || current_user.social_accounts.new
  end

  def edit
    @social_account = current_user.social_account || current_user.social_accounts.new
    @attribute = params[:attribute]
  end

  def update
    outcome = SocialAccounts::Update.run(user: current_user, attrs: params.permit!.to_h, update_attribute: params[:attribute])

    render json: json_response(outcome, { redirect_to: lines_user_bot_settings_social_account_path(anchor: params[:attribute]) })
  end

  def webhook_modal
    @social_account = current_user.social_accounts.first

    if @social_account
      render layout: false
    else
      head :ok
    end
  end

  private

  def social_account_params
    params.require(:social_account).permit(:label, :channel_id, :channel_token, :channel_secret, :basic_id)
  end
end
