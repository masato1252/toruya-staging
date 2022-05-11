# frozen_string_literal: true

require "message_encryptor"

class Lines::UserBot::Settings::SocialAccountsController < Lines::UserBotDashboardController
  def message_api
    @social_account = current_user.social_account || current_user.social_accounts.new
  end

  def login_api
    @social_account = current_user.social_account || current_user.social_accounts.new
  end

  def edit
    @social_account = current_user.social_account || current_user.social_accounts.new
    @attribute = params[:attribute]
    @previous_path =
      case params[:attribute]
      when "login_channel_id", "login_channel_secret"
        login_api_lines_user_bot_settings_social_account_path(anchor: params[:attribute])
      else
        message_api_lines_user_bot_settings_social_account_path(anchor: params[:attribute])
      end
  end

  def update
    outcome = SocialAccounts::Update.run(user: current_user, attrs: params.permit!.to_h, update_attribute: params[:attribute])

    social_account  = current_user.social_account

    case params[:attribute]
    when "login_channel_id", "login_channel_secret"
      render json: json_response(outcome, { redirect_to: login_api_lines_user_bot_settings_social_account_path(anchor: params[:attribute]) })
    else
      render json: json_response(outcome, { redirect_to: message_api_lines_user_bot_settings_social_account_path(anchor: params[:attribute]) })
    end
  end

  def webhook_modal
    @social_account = current_user.social_account

    if @social_account
      render layout: false
    else
      head :ok
    end
  end

  def callback_modal
    @social_account = current_user.social_account

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
