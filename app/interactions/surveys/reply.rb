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
        integer :survey_activity_id, default: nil
      end
    end

    validate :validate_required_questions
    validate :validate_answer_formats
    validate :validate_activity_participants

    def execute
      survey_response = nil

      owner.with_lock do
        # Check for duplicate activities inside the lock
        if has_duplicate_activities?
          errors.add(:survey, :duplicate_activity, url: existing_survey_response_url)
          return nil
        end

        survey_response = SurveyResponse.create!(
          survey: survey,
          owner: owner,
          uuid: SecureRandom.uuid
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
          elsif question.activity?
            # For activity questions
            activity = question.activities.find(answer[:survey_activity_id])

            compose(Surveys::ReplyActivity,
              survey: survey,
              owner: owner,
              survey_response: survey_response,
              question: question,
              activity: activity,
              question_description: question_description
            )

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

      if survey_response.is_activity?
        Notifiers::Customers::Surveys::ActivityPendingResponse.perform_later(survey_response: survey_response, receiver: owner)
        Notifiers::Users::Surveys::ActivityPendingResponse.perform_later(survey_response: survey_response, receiver: survey.user)
      else
        Notifiers::Customers::Surveys::SurveyPendingResponse.perform_later(survey_response: survey_response, receiver: owner)
        Notifiers::Users::Surveys::SurveyPendingResponse.perform_later(survey_response: survey_response, receiver: survey.user)
      end

      survey_response
    rescue ActiveRecord::RecordInvalid => e
      errors.add(:base, e.message)
    end

    private

    def has_duplicate_activities?
      if activity_ids.any?
        SurveyResponse.where(
          survey: survey,
          owner: owner,
          survey_activity_id: activity_ids
        ).exists?
      end
    end

    def activity_ids
      @activity_ids ||= answers.map { |answer| answer[:survey_activity_id] }.compact
    end

    def existing_survey_response
      @existing_survey_response ||= SurveyResponse.where(
        survey: survey,
        owner: owner,
        survey_activity_id: activity_ids
      ).order(created_at: :desc).first
    end

    def existing_survey_response_url
      Rails.application.routes.url_helpers.reply_survey_url(survey.slug, existing_survey_response.uuid)
    end

    def validate_required_questions
      return false if activity_ids.empty?

      # Check if owner has already responded to any of these activities
      QuestionAnswer.joins(:survey_response)
        .where(survey_activity_id: activity_ids)
        .where(survey_responses: { owner_id: owner.id, owner_type: owner.class.name })
        .exists?
    end

    def validate_required_questions
      required_questions = survey.questions.where(required: true)
      answered_question_ids = answers.map { |a| a[:survey_question_id] }

      missing_required = required_questions.reject { |q| answered_question_ids.include?(q.id) }

      if missing_required.any?
        errors.add(:survey, :missing_required)
      end
    end

    def validate_activity_participants
      activity_answers = answers.select { |answer|
        question = survey.questions.find(answer[:survey_question_id])
        question.activity? && answer[:survey_activity_id].present?
      }

      activity_answers.each do |answer|
        activity = SurveyActivity.find(answer[:survey_activity_id])
        next unless activity.max_participants

        current_participants = activity.survey_responses.active.count
        if current_participants >= activity.max_participants
          errors.add(:survey, :activity_full)
        end
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
          if answer[:survey_option_ids].present?
            errors.add(:survey, :options_not_allowed)
          end
          if answer[:survey_activity_id].present?
            errors.add(:survey, :activity_not_allowed)
          end
        when 'single_selection'
          if answer[:survey_option_ids].blank? || answer[:survey_option_ids].size != 1
            errors.add(:survey, :invalid_single_selection)
          end
          if answer[:text_answer].present?
            errors.add(:survey, :text_answer_not_allowed)
          end
          if answer[:survey_activity_id].present?
            errors.add(:survey, :activity_not_allowed)
          end
          unless question.options.exists?(id: answer[:survey_option_ids].first)
            errors.add(:survey, :invalid_option)
          end
        when 'multiple_selection'
          if answer[:survey_option_ids].blank?
            errors.add(:survey, :invalid_multiple_selection)
          end
          if answer[:text_answer].present?
            errors.add(:survey, :text_answer_not_allowed)
          end
          if answer[:survey_activity_id].present?
            errors.add(:survey, :activity_not_allowed)
          end
          answer[:survey_option_ids].each do |option_id|
            unless question.options.exists?(id: option_id)
              errors.add(:survey, :invalid_option)
            end
          end
        when 'activity'
          if answer[:survey_option_ids].present?
            errors.add(:survey, :options_not_allowed)
          end
          if answer[:text_answer].present?
            errors.add(:survey, :text_answer_not_allowed)
          end
          if answer[:survey_activity_id].blank?
            errors.add(:survey, :invalid_activity_selection)
          end
          if answer[:survey_activity_id].present?
            unless question.activities.exists?(id: answer[:survey_activity_id])
              errors.add(:survey, :invalid_option)
            end
          end
        end
      end
    end
  end
end
