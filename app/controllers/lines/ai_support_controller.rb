# frozen_string_literal: true

require "message_encryptor"
require "line_client"

class Lines::AiSupportController < ActionController::Base
  include ControllerHelpers
  layout "booking"
  before_action :current_social_user

  def new
  end

  def create
    ::TrackProcessedActionJob.perform_later("toruya", "ai_reply", { category: params[:category] })

    question = "#{params[:category]}\n#{params[:ai_question]}"
    ai_uid = SecureRandom.uuid
    ::AiSupports::Create.perform_later(
      user_id: "toruya",
      question: question,
      social_user: current_social_user,
      ai_uid: ai_uid
    )

    render json: { ai_uid: ai_uid }
  end

  def response_check
    if message = SocialUserMessage.where(social_user: current_social_user, ai_uid: params[:ai_uid], message_type: SocialUserMessage.message_types[:user_ai_response]).take
      render json: { message: message.raw_content }
    else
      render json: { message: "" }
    end
  end

  def current_social_user
    @current_social_user ||= SocialUser.find_by(social_service_user_id: MessageEncryptor.decrypt(params[:encrypted_social_service_user_id]))
  end
  helper_method :current_social_user
end
