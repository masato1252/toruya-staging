# frozen_string_literal: true

class Settings::SocialAccountsController < SettingsController
  before_action :set_social_account, only: [:edit, :update, :destroy]

  def index
    if social_account = current_user.social_accounts.first
      redirect_to settings_user_social_account_path(current_user, social_account)
    else
      redirect_to new_settings_user_social_account_path(current_user)
    end
  end

  def show
    @social_account = current_user.social_accounts.first
  end

  def new
    if social_account = current_user.social_accounts.first
      redirect_to edit_settings_user_social_account_path(current_user, social_account)
    end

    @social_account = current_user.social_accounts.new
  end

  def edit
  end

  def create
    if social_account = current_user.social_accounts.first
      redirect_to edit_settings_user_social_account_path(current_user, social_account)
    end

    outcome = SocialAccounts::Save.run(
      user: current_user,
      channel_id: social_account_params[:channel_id],
      channel_token: social_account_params[:channel_token],
      channel_secret: social_account_params[:channel_secret],
      label: social_account_params[:label],
      basic_id: social_account_params[:basic_id]
    )

    if outcome.valid?
      redirect_to settings_user_social_account_path(current_user, outcome.result), notice: I18n.t("common.create_successfully_message")
    else
      @social_account = current_user.social_accounts.new
      @social_account.errors.merge!(outcome.errors)
      render :new
    end
  end

  def update
    outcome = SocialAccounts::Save.run(
      user: current_user,
      social_account: @social_account,
      channel_id: social_account_params[:channel_id],
      channel_token: social_account_params[:channel_token],
      channel_secret: social_account_params[:channel_secret],
      label: social_account_params[:label],
      basic_id: social_account_params[:basic_id]
    )

    if outcome.valid?
      redirect_to settings_user_social_account_path(current_user, outcome.result), notice: I18n.t("common.update_successfully_message")
    else
      @social_account.errors.merge!(outcome.errors)
      render :edit
    end
  end

  def destroy
    @social_account.destroy

    redirect_to settings_user_social_accounts_path(current_user), notice: I18n.t("common.delete_successfully_message")
  end

  private

  def set_social_account
    @social_account = current_user.social_accounts.find(params[:id])
  end

  def social_account_params
    params.require(:social_account).permit(:label, :channel_id, :channel_token, :channel_secret, :basic_id)
  end
end
