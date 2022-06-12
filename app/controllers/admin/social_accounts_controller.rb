# frozen_string_literal: true

module Admin
  class SocialAccountsController < AdminController
    def destroy
      social_user = SocialUser.find_by(social_service_user_id: params[:customer_id])
      SocialAccounts::Clean.run!(user: social_user.user)

      render json: {
        status: "successful",
        redirect_to: admin_chats_path(social_service_user_id: params[:customer_id])
      }
    end
  end
end
