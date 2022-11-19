# frozen_string_literal: true

module Admin
  class ChatsController < AdminController
    def index
      @selected_social_user = SocialUser.find_by(social_service_user_id: params[:social_service_user_id]) || User.find_by(id: params[:user_id])&.social_user
    end

    def create
      SocialUserMessages::Create.run!(
        social_user: SocialUser.find_by!(social_service_user_id: params[:customer_id]),
        content: params[:message],
        readed: true,
        message_type: SocialUserMessage.message_types[:admin],
        schedule_at: params[:schedule_at] ? Time.zone.parse(params[:schedule_at]) : nil
      )

      render json: {
        status: "successful",
        redirect_to: admin_chats_path(social_service_user_id: params[:customer_id])
      }
    end

    def destroy
      message = SocialUserMessage.find(params[:id])

      unless message.sent_at
        message.destroy
      end

      render json: {
        status: "successful",
        redirect_to: admin_chats_path(social_service_user_id: params[:customer_id])
      }
    end
  end
end
