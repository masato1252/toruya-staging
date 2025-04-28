# frozen_string_literal: true

module Lines
  module UserBot
    module Surveys
      class SurveyResponsesController < Lines::UserBotDashboardController
        # The response for survey activities
        before_action :set_survey
        before_action :set_activity
        before_action :set_survey_response

        def show
          # @survey, @activity, @survey_response are set by before_actions
        end

        def accept
          SurveyResponses::Accept.run(survey_response: @survey_response)
          redirect_to lines_user_bot_survey_activity_path(business_owner_id, @survey, @activity), notice: t('user_bot.dashboards.surveys.activities.accept_successfully_message')
        end

        def cancel
          SurveyResponses::Cancel.run(survey_response: @survey_response)
          redirect_to lines_user_bot_survey_activity_path(business_owner_id, @survey, @activity), notice: t('user_bot.dashboards.surveys.activities.cancel_successfully_message')
        end

        def pending
          SurveyResponses::Pend.run(survey_response: @survey_response)

          redirect_to lines_user_bot_survey_activity_path(business_owner_id, @survey, @activity), notice: t('user_bot.dashboards.surveys.activities.pending_successfully_message')
        end

        private

        def set_survey
          @survey = Current.business_owner.surveys.find(params[:survey_id])
        end

        def set_activity
          @activity = @survey.activities.find(params[:activity_id])
        end

        def set_survey_response
          @survey_response = @activity.survey_responses.find(params[:id])
        end
      end
    end
  end
end