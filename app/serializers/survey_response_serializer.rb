# frozen_string_literal: true

class SurveyResponseSerializer
  include JSONAPI::Serializer

  attributes :id
  attribute :survey do |object|
    SurveySerializer.new(object.survey).serializable_hash[:data][:attributes]
  end

  attribute :question_answers do |object|
    object.question_answers.map do |answer|
      {
        id: answer.id,
        text_answer: answer.text_answer,
        survey_question_id: answer.survey_question_id,
        survey_option_id: answer.survey_option_id
      }
    end
  end
end
