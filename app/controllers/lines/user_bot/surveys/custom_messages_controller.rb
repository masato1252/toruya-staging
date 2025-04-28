# frozen_string_literal: true

module Lines
  module UserBot
    module Surveys
      class CustomMessagesController < Lines::UserBotDashboardController
        before_action :set_survey

        def index
          if @survey.activities.any?
            @pending_message = CustomMessage.scenario_of(@survey, CustomMessages::Customers::Template::ACTIVITY_PENDING_RESPONSE).right_away.first
            @accepted_message = CustomMessage.scenario_of(@survey, CustomMessages::Customers::Template::ACTIVITY_ACCEPTED_RESPONSE).right_away.first
            @canceled_message = CustomMessage.scenario_of(@survey, CustomMessages::Customers::Template::ACTIVITY_CANCELED_RESPONSE).right_away.first
            @one_day_reminder_message = CustomMessage.scenario_of(@survey, CustomMessages::Customers::Template::ACTIVITY_ONE_DAY_REMINDER).right_away.first
            # Might support this later
            # @sequence_messages = CustomMessage.scenario_of(@survey, CustomMessages::Customers::Template::ACTIVITY_CUSTOM_MESSAGE).order("before_minutes ASC")
          else
            @survey_pending_message = CustomMessage.scenario_of(@survey, CustomMessages::Customers::Template::SURVEY_PENDING_RESPONSE).right_away.first
          end

          @sequence_messages = CustomMessage.none
        end

        def edit_scenario
          @survey = Current.business_owner.surveys.find(params[:id])
          @custom_message = CustomMessage.find_by(service: @survey, id: params[:custom_message_id])
          @template = @custom_message&.content || ::CustomMessages::Customers::Template.run!(product: @survey, scenario: params[:scenario])
        end

        private

        def set_survey
          @survey = Current.business_owner.surveys.find(params[:id])
        end
      end
    end
  end
end