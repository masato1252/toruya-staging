# frozen_string_literal: true

module Notifiers
  module Users
    module Surveys
      class ActivityPendingResponse < Base
        deliver_by_priority [:email]

        object :survey_response

        validate :receiver_should_be_user

        def message
          I18n.t("notifier.survey.users.activity_pending_message",
            user_name: receiver.message_name,
            survey_name: survey.title,
            activity_name: survey_activity.name,
            survey_response_url: survey_response.survey_response_url
          )
        end

        private

        def survey
          survey_response.survey
        end

        def survey_activity
          survey_response.survey_activity
        end
      end
    end
  end
end
