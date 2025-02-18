# frozen_string_literal: true

class SurveySerializer
  include JSONAPI::Serializer
  attribute :id, :title, :description

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
            position: option.position,
          }
        end
      }
    end
  end
end
