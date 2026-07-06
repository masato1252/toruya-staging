# frozen_string_literal: true

module Lines
  module UserBot
    module Surveys
      class ResponsesController < Lines::UserBotDashboardController
        include CrossAccountRedirect
        redirect_to_correct_owner_for :surveys

        # The response for survey
        before_action :set_survey
        before_action :set_survey_response, only: [:show]

        def index
          if ENV["COMPAT_API_READ_ENABLED"] == "true"
            @survey = nil
            render :index_compat
            return
          end

          @survey_responses = @survey.responses
        end

        def show
          if ENV["COMPAT_API_READ_ENABLED"] == "true"
            render :show_compat
            return
          end
        end

        private

        def set_survey
          return if ENV["COMPAT_API_READ_ENABLED"] == "true"

          @survey = Current.business_owner.surveys.find(params[:id])
        end

        def set_survey_response
          return if ENV["COMPAT_API_READ_ENABLED"] == "true"

          @survey_response = @survey.responses.find(params[:survey_response_id])
        end
      end
    end
  end
end