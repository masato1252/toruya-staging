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
    ::TrackProcessedActionJob.perform_later("toruya", "ai_reply", {})

    question = "#{params[:category]}\n#{params[:ai_question]}"
    outcome = Ai::Query.run(user_id: "toruya", question: question)

    SocialUserMessages::CreateAiMessage.run(social_user: current_social_user, ai_question: question, ai_response: outcome.result[:message])
    return_json_response(outcome, outcome.result)
  end

  def current_social_user
    @current_social_user ||= SocialUser.find_by(social_service_user_id: MessageEncryptor.decrypt(params[:encrypted_social_service_user_id]))
  end
  helper_method :current_social_user
end
