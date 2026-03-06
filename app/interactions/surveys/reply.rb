module Surveys
  class Reply < ActiveInteraction::Base
    include ActionView::Helpers::SanitizeHelper
    include ActionView::Helpers::TextHelper

    object :survey
    object :owner, class: ApplicationRecord
    array :answers do
      hash do
        integer :survey_question_id
        string :text_answer, default: nil
        array :survey_option_ids, default: []
      end
    end

    validate :validate_required_questions
    validate :validate_answer_formats

    def execute
      survey_response = nil

      owner.with_lock do
        survey_response = SurveyResponse.create!(
          survey: survey,
          owner: owner,
          uuid: SecureRandom.uuid
        )

        answers.each do |answer|
          question = survey.questions.find(answer[:survey_question_id])
          question_description = strip_tags(question.description).truncate_words(30)

          if question.multiple_selection? && answer[:survey_option_ids].present?
            answer[:survey_option_ids].each do |option_id|
              option_content = strip_tags(question.options.find(option_id).content)
              survey_response.question_answers.create!(
                survey_question: question,
                survey_option_id: option_id,
                survey_question_snapshot: question_description,
                survey_option_snapshot: option_content
              )
            end
          else
            option_content = answer[:survey_option_ids]&.first ?
              strip_tags(question.options.find_by(id: answer[:survey_option_ids].first)&.content) :
              nil

            survey_response.question_answers.create!(
              survey_question: question,
              survey_option_id: answer[:survey_option_ids]&.first,
              survey_question_snapshot: question_description,
              survey_option_snapshot: option_content,
              text_answer: answer[:text_answer].presence
            )
          end
        end
      end

      Notifiers::Customers::Surveys::SurveyPendingResponse.perform_later(survey_response: survey_response, receiver: owner)
      if survey.regular?
        Notifiers::Users::Surveys::SurveyPendingResponse.perform_later(survey_response: survey_response, receiver: survey.user)
      end

      survey_response
    rescue ActiveRecord::RecordInvalid => e
      errors.add(:base, e.message)
    end

    private

    def validate_required_questions
      required_questions = survey.questions.where(required: true)
      answered_question_ids = answers.map { |a| a[:survey_question_id] }

      missing_required = required_questions.reject { |q| answered_question_ids.include?(q.id) }

      if missing_required.any?
        errors.add(:survey, :missing_required)
      end
    end

    def validate_answer_formats
      answers.each do |answer|
        question = survey.questions.find(answer[:survey_question_id])

        case question.question_type
        when 'text'
          if answer[:text_answer].blank?
            errors.add(:survey, :invalid_text_answer)
          end
        when 'single_selection'
          if answer[:survey_option_ids].blank? || answer[:survey_option_ids].size != 1
            errors.add(:survey, :invalid_single_selection)
          end
          unless question.options.exists?(id: answer[:survey_option_ids].first)
            errors.add(:survey, :invalid_option)
          end
        when 'multiple_selection'
          if answer[:survey_option_ids].blank?
            errors.add(:survey, :invalid_multiple_selection)
          end
          answer[:survey_option_ids].each do |option_id|
            unless question.options.exists?(id: option_id)
              errors.add(:survey, :invalid_option)
            end
          end
        end
      end
    end
  end
end
