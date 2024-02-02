# frozen_string_literal: true

module Admin
  class ChatsController < AdminController
    skip_before_action :super_admin_required
    before_action :chat_permission_required

    def index
      @selected_social_user = SocialUser.find_by(social_service_user_id: params[:social_service_user_id]) || User.find_by(id: params[:user_id])&.social_user
    end

    def create
      if params[:message].present?
        SocialUserMessages::Create.run!(
          social_user: SocialUser.find_by!(social_service_user_id: params[:customer_id]),
          content: params[:message],
          readed: true,
          message_type: SocialUserMessage.message_types[:admin],
          schedule_at: params[:schedule_at] ? Time.zone.parse(params[:schedule_at]) : nil
        )
      end

    if params[:image].present?
      outcome = SocialUserMessages::Create.run(
        social_user: SocialUser.find_by!(social_service_user_id: params[:customer_id]),
        content: {
          originalContentUrl: "tmp_original_content_url",
          previewImageUrl: "tmp_preview_image_url"
        }.to_json,
        image: params[:image],
        readed: true,
        message_type: SocialUserMessage.message_types[:admin],
        content_type: SocialMessages::Create::IMAGE_TYPE,
        schedule_at: params[:schedule_at] ? Time.zone.parse(params[:schedule_at]) : nil
      )
    end

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

    def ai_reply
      ::TrackProcessedActionJob.perform_later("toruya", "ai_reply", { category: "admin" })

      outcome = Ai::Query.run(user_id: "toruya", question: params[:question], prompt: params[:prompt])
      return_json_response(outcome, outcome.result)
    end

    private

    def chat_permission_required
      if !current_user.super_admin? && !current_user.can_admin_chat?
        head :not_found
      end
    end
  end
end
