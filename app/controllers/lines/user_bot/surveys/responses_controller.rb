# frozen_string_literal: true

module Lines
  module UserBot
    module Surveys
      class ResponsesController < Lines::UserBotDashboardController
        # The response for survey
        before_action :set_survey
        before_action :set_survey_response, only: [:show]

        def index
          @survey_responses = @survey.responses
        end

        def show
          # @survey, @survey_response are set by before_actions
        end

        private

        def set_survey
          @survey = Current.business_owner.surveys.find(params[:id])
        end

        def set_survey_response
          @survey_response = @survey.responses.find(params[:survey_response_id])
        end
      end
    end
  end
end