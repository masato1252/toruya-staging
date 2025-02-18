module Surveys
  class Reply < ActiveInteraction::Base
    include ActionView::Helpers::SanitizeHelper
    include ActionView::Helpers::TextHelper  # for truncate_words

    object :survey
    object :owner, class: ApplicationRecord # who filled the survey
    array :answers do
      hash do
        integer :survey_question_id
        string :text_answer, default: nil
        array :survey_option_ids, default: [] # Change to array for multiple selection
      end
    end

    validate :validate_required_questions
    validate :validate_answer_formats

    def execute
      survey_response = nil

      Survey.transaction do
        survey_response = SurveyResponse.create!(
          survey: survey,
          owner: owner
        )

        answers.each do |answer|
          question = survey.questions.find(answer[:survey_question_id])
          question_description = strip_tags(question.description).truncate_words(30)

          # For multiple selection, create multiple answers
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
            # For single selection and text questions
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

      survey_response
    rescue ActiveRecord::RecordInvalid => e
      errors.add(:base, e.message)
    end

    private

    def validate_required_questions
      required_question_ids = survey.questions.where(required: true).pluck(:id)
      answered_question_ids = answers.map { |a| a[:survey_question_id] }

      missing_required = required_question_ids - answered_question_ids

      if missing_required.any?
        errors.add(:answers, "Missing answers for required questions: #{missing_required.join(', ')}")
      end
    end

    def validate_answer_formats
      answers.each do |answer|
        question = survey.questions.find(answer[:survey_question_id])

        case question.question_type
        when 'text'
          if answer[:text_answer].blank?
            errors.add(:answers, "Text answer required for question #{question.id}")
          end
          if answer[:survey_option_ids].present?
            errors.add(:answers, "Survey options should not be present for text question #{question.id}")
          end
        when 'single_selection'
          if answer[:survey_option_ids].blank? || answer[:survey_option_ids].size != 1
            errors.add(:answers, "Single option selection required for question #{question.id}")
          end
          if answer[:text_answer].present?
            errors.add(:answers, "Text answer should not be present for single selection question #{question.id}")
          end
          unless question.options.exists?(id: answer[:survey_option_ids].first)
            errors.add(:answers, "Invalid option selected for question #{question.id}")
          end
        when 'multiple_selection'
          if answer[:survey_option_ids].blank?
            errors.add(:answers, "At least one option must be selected for multiple selection question #{question.id}")
          end
          if answer[:text_answer].present?
            errors.add(:answers, "Text answer should not be present for multiple selection question #{question.id}")
          end
          answer[:survey_option_ids].each do |option_id|
            unless question.options.exists?(id: option_id)
              errors.add(:answers, "Invalid option selected for question #{question.id}")
            end
          end
        when 'dropdown'
          if answer[:survey_option_ids].blank? || answer[:survey_option_ids].size != 1
            errors.add(:answers, "Single option selection required for question #{question.id}")
          end
          if answer[:text_answer].present?
            errors.add(:answers, "Text answer should not be present for dropdown question #{question.id}")
          end
          unless question.options.exists?(id: answer[:survey_option_ids].first)
            errors.add(:answers, "Invalid option selected for question #{question.id}")
          end
        end
      end
    end
  end
end