module Surveys
  class ReplyActivity < ActiveInteraction::Base
    object :survey
    object :owner, class: ApplicationRecord # customer
    object :survey_response, class: SurveyResponse
    object :question, class: SurveyQuestion
    object :activity, class: SurveyActivity
    string :question_description

    def execute
      survey_response.update!(survey_activity: activity)

      survey_response.question_answers.create!(
        survey_question: question,
        survey_activity: activity,
        survey_question_snapshot: question_description,
        survey_activity_snapshot: activity.name
      )

      # Create reservation and reservation customer for the activity
      activity.activity_slots.each do |slot|
        compose(SurveyActivitySlots::UpsertReservation,
          survey: survey,
          activity: activity,
          slot: slot,
          customer: owner
        )
      end
    end
  end
end
