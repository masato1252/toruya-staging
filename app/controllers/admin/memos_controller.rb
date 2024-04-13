# frozen_string_literal: true

module Admin
  class MemosController < AdminController
    def create
      user = SocialUser.find_by(social_service_user_id: params[:social_service_user_id])
      user.same_social_user_scope.each do |s_user|
        s_user.memo_list = params[:memo]
        s_user.save
      end

      render json: {
        status: "successful",
        redirect_to: admin_chats_path(params[:user_id].presence ? { user_id: params[:user_id] } : { social_service_user_id: params[:social_service_user_id] })
      }
    end
  end
end
