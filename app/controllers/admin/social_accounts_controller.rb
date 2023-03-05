# frozen_string_literal: true

module Admin
  class SocialAccountsController < AdminController
    def edit
      @social_user = SocialUser.find_by!(social_service_user_id: params[:social_service_user_id])
      user = @social_user.user
      @social_account = user.social_account || user.social_accounts.new
    end

    def update
      social_user = SocialUser.find_by!(social_service_user_id: params[:social_service_user_id])
      user = social_user.user
      social_account = user.social_account || user.social_accounts.new

      outcome = SocialAccounts::Save.run(
        user: user,
        social_account: social_account,
        channel_id: social_account_params[:channel_id],
        channel_token: social_account_params[:channel_token],
        channel_secret: social_account_params[:channel_secret],
        label: social_account_params[:label],
        basic_id: social_account_params[:basic_id],
        login_channel_id: social_account_params[:login_channel_id],
        login_channel_secret: social_account_params[:login_channel_secret]
      )

      redirect_to admin_chats_path(user_id: user.id)
    end

    def destroy
      social_user = SocialUser.find_by!(social_service_user_id: params[:social_service_user_id])
      user = social_user.user
      SocialAccounts::Clean.run!(user: user)

      redirect_to admin_chats_path(user_id: user.id)
    end

    private

    def social_account_params
      params.require(:social_account).permit(:label, :channel_id, :channel_token, :channel_secret, :basic_id, :login_channel_id, :login_channel_secret)
    end
  end
end
