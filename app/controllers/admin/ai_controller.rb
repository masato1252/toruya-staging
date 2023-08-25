# frozen_string_literal: true

module Admin
  class AiController < AdminController
    def index; end

    def create
      Ai::Build.run(user_id: "toruya", urls: Array.wrap(params[:url])) if params[:url].present?

      redirect_back fallback_location: admin_ai_index_path, notice: "Submitted"
    end
  end
end
