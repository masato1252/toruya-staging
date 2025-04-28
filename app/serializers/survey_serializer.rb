# frozen_string_literal: true

class SurveySerializer
  include JSONAPI::Serializer
  attributes :id, :title, :description, :slug, :active

  attribute :questions do |survey|
    survey.questions.map do |question|
      {
        id: question.id,
        description: question.description,
        question_type: question.question_type,
        required: question.required,
        position: question.position,
        options: question.options.map do |option|
          {
            id: option.id,
            content: option.content,
            position: option.position
          }
        end,
        activities: question.activities.includes(:survey_responses).map do |activity|
          {
            id: activity.id,
            name: activity.name,
            position: activity.position,
            max_participants: activity.max_participants,
            participants: activity.survey_responses.active.count,
            is_full: activity.survey_responses.active.count >= activity.max_participants,
            price_cents: activity.price_cents,
            datetime_slots: activity.activity_slots.map do |slot|
              {
                id: slot.id,
                start_date: slot.start_time.strftime("%Y-%m-%d"),
                start_time: slot.start_time.strftime("%H:%M"),
                end_date: slot.end_time.strftime("%Y-%m-%d"),
                end_time: slot.end_time.strftime("%H:%M")
              }
            end
          }
        end
      }
    end
  end
end
