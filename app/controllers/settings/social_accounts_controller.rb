class Settings::SocialAccountsController < SettingsController
  before_action :set_social_account, only: [:edit, :update, :destroy]

  def index
    @social_accounts = super_user.social_accounts.order("id")
  end

  def new
    @social_account = super_user.social_accounts.new
  end

  def edit
  end

  def create
    outcome = SocialAccounts::Save.run(
      user: super_user,
      channel_id: social_account_params[:channel_id],
      channel_token: social_account_params[:channel_token],
      channel_secret: social_account_params[:channel_secret],
      label: social_account_params[:label],
    )

    if outcome.valid?
      redirect_to settings_user_social_accounts_path(super_user), notice: I18n.t("common.create_successfully_message")
    else
      render :new
    end
  end

  def update
    outcome = SocialAccounts::Save.run(
      user: super_user,
      social_account: @social_account,
      channel_id: social_account_params[:channel_id],
      channel_token: social_account_params[:channel_token],
      channel_secret: social_account_params[:channel_secret],
      label: social_account_params[:label],
    )

    if outcome.valid?
      redirect_to settings_user_social_accounts_path(super_user), notice: I18n.t("common.update_successfully_message")
    else
      render :edit
    end
  end

  def destroy
    @social_account.destroy

    redirect_to settings_user_social_accounts_path(super_user), notice: I18n.t("common.delete_successfully_message")
  end

  private

  def set_social_account
    @social_account = super_user.social_accounts.find(params[:id])
  end

  def social_account_params
    params.require(:social_account).permit(:label, :channel_id, :channel_token, :channel_secret)
  end
end
