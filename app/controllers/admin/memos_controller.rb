# frozen_string_literal: true

module Admin
  class MemosController < AdminController
    def create
      user = SocialUser.find_by(social_service_user_id: params[:customer_id])
      user.memo_list = params[:memo]
      user.save

      render json: {
        status: "successful",
        redirect_to: admin_chats_path(social_service_user_id: params[:customer_id])
      }
    end
  end
end
