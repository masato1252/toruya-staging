# frozen_string_literal: true

require "message_encryptor"

class Lines::UserBot::Settings::SocialAccountsController < Lines::UserBotDashboardController
  def new
  end

  def reset
    SocialAccounts::Clean.run!(user: Current.business_owner)

    redirect_back(fallback_location: lines_user_bot_settings_path(business_owner_id: business_owner_id))
  end

  def message_api
    @social_account = Current.business_owner.social_account || Current.business_owner.social_accounts.new
  end

  def login_api
    @social_account = Current.business_owner.social_account || Current.business_owner.social_accounts.new
  end

  def edit
    @social_account = Current.business_owner.social_account || Current.business_owner.social_accounts.new
    @attribute = params[:attribute]
    @previous_path =
      case params[:attribute]
      when "login_channel_id", "login_channel_secret"
        login_api_lines_user_bot_settings_social_account_path(anchor: params[:attribute], business_owner_id: business_owner_id)
      else
        message_api_lines_user_bot_settings_social_account_path(anchor: params[:attribute], business_owner_id: business_owner_id)
      end
  end

  def update
    outcome = SocialAccounts::Update.run(user: Current.business_owner, attrs: params.permit!.to_h, update_attribute: params[:attribute])

    social_account  = Current.business_owner.social_account

    case params[:attribute]
    when "login_channel_id", "login_channel_secret"
      return_json_response(outcome, { redirect_to: login_api_lines_user_bot_settings_social_account_path(anchor: params[:attribute], business_owner_id: business_owner_id) })
    else
      return_json_response(outcome, { redirect_to: message_api_lines_user_bot_settings_social_account_path(anchor: params[:attribute], business_owner_id: business_owner_id) })
    end
  end

  def webhook_modal
    @social_account = Current.business_owner.social_account

    if @social_account
      render layout: false
    else
      head :ok
    end
  end

  def callback_modal
    @social_account = Current.business_owner.social_account

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
