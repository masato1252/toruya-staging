# frozen_string_literal: true

module Admin
  class SocialAccountsController < AdminController
    def edit
      user = User.find(params[:user_id])
      @social_account = user.social_account || user.social_accounts.new
    end

    def update
      user = User.find(params[:user_id])
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
      user = User.find(params[:user_id])
      SocialAccounts::Clean.run!(user: user)

      redirect_to admin_chats_path(user_id: user.id)
    end

    def line_finished_message
      user = User.find(params[:user_id])

      Notifiers::Users::LineSettings::FinishedMessage.run!(receiver: user.social_user)
      Notifiers::Users::LineSettings::FinishedFlex.run!(receiver: user.social_user)
      Notifiers::Users::LineSettings::FinishedVideo.run!(receiver: user.social_user)

      redirect_to admin_chats_path(user_id: user.id), notice: "Successfully"
    end

    private

    def social_account_params
      params.require(:social_account).permit(:label, :channel_id, :channel_token, :channel_secret, :basic_id, :login_channel_id, :login_channel_secret)
    end
  end
end