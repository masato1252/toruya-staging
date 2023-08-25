# frozen_string_literal: true

module Admin
  class AiController < AdminController
    def index; end

    def create
      Ai::Build.run(user_id: "toruya", urls: Array.wrap(params[:url])) if params[:url].present?

      redirect_back fallback_location: admin_ai_index_path, notice: "Submitted"
    end

    def correct
      ::TrackProcessedActionJob.perform_later(SecureRandom.uuid, "ai_evaluate", { correct: true })
    end

    def incorrect
      ::TrackProcessedActionJob.perform_later(SecureRandom.uuid, "ai_evaluate", { correct: false })
    end
  end
end
