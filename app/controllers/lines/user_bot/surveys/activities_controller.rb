# frozen_string_literal: true

module Lines
  module UserBot
    module Surveys
      class ActivitiesController < Lines::UserBotDashboardController
        before_action :set_survey

        def index
          @activities = @survey.activities
        end

        def show
          @activity = @survey.activities.find(params[:id])
          @responses = @activity.survey_responses
          @broadcasts = @activity.broadcasts.ordered
        end

        private

        def set_survey
          @survey = Current.business_owner.surveys.find(params[:survey_id])
        end
      end
    end
  end
end