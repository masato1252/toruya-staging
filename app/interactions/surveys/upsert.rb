module Surveys
  class Upsert < ActiveInteraction::Base
    object :user
    object :owner, class: ApplicationRecord
    object :survey, default: nil

    string :title, default: nil
    string :description, default: nil

    array :questions do
      hash do
        integer :id, default: nil
        string :description
        string :question_type
        boolean :required, default: false
        integer :position
        array :options, default: [] do
          hash do
            integer :id, default: nil
            string :content
            integer :position
          end
        end
      end
    end

    def execute
      @survey = survey || Survey.new
      @survey.assign_attributes(
        user: user,
        owner: owner,
        title: title,
        description: description
      )

      Survey.transaction do
        @survey.save!

        # Track existing and processed questions
        existing_question_ids = survey&.questions&.where(deleted_at: nil)&.pluck(:id) || []
        processed_question_ids = []

        questions.each do |question_params|
          # Try to find existing question by ID, including soft-deleted ones
          question = if question_params[:id].present?
                      @survey.questions.find_by(id: question_params[:id])
                    end

          if question
            # Update existing question and restore if soft-deleted
            question.update!(
              description: question_params[:description],
              question_type: question_params[:question_type],
              required: question_params[:required],
              position: question_params[:position],
              deleted_at: nil
            )

            # If question type is changed to text, soft delete all options
            if question_params[:question_type] == 'text'
              question.options.update_all(deleted_at: Time.current)
            end
          else
            # Create new question
            question = @survey.questions.create!(
              description: question_params[:description],
              question_type: question_params[:question_type],
              required: question_params[:required],
              position: question_params[:position]
            )
          end

          processed_question_ids << question.id

          if SurveyQuestion::SELECTION_TYPES.include?(question_params[:question_type])
            # Track existing and processed option ids
            existing_option_ids = question.options.where(deleted_at: nil).pluck(:id)
            processed_option_ids = []

            question_params[:options].each do |option_params|
              # Update or create options, including soft-deleted ones
              option = if option_params[:id].present?
                        question.options.find_by(id: option_params[:id])
                      end

              if option
                # Restore if soft-deleted and update existing option
                option.update!(
                  content: option_params[:content],
                  position: option_params[:position],
                  deleted_at: nil
                )
              else
                # Create new option
                option = question.options.create!(
                  content: option_params[:content],
                  position: option_params[:position]
                )
              end

              processed_option_ids << option.id
            end

            # Soft delete options that weren't in the update
            question.options
                   .where(deleted_at: nil)
                   .where(id: existing_option_ids - processed_option_ids)
                   .update_all(deleted_at: Time.current)
          end
        end

        # Soft delete questions that weren't in the update
        @survey.questions
               .where(deleted_at: nil)
               .where(id: existing_question_ids - processed_question_ids)
               .update_all(deleted_at: Time.current)
      end

      @survey
    rescue ActiveRecord::RecordInvalid => e
      errors.add(:base, e.message)
    end

    private

    def validate_questions
      questions.each_with_index do |question, index|
        unless SurveyQuestion.question_types.keys.include?(question[:question_type])
          errors.add(:questions, "Question #{index + 1} has invalid type")
        end

        if SurveyQuestion::SELECTION_TYPES.include?(question[:question_type]) &&
           question[:options].blank?
          errors.add(:questions, "Question #{index + 1} requires options")
        end
      end
    end
  end
end