module Surveys
  class Upsert < ActiveInteraction::Base
    object :user
    object :owner, class: ApplicationRecord
    object :survey, default: nil

    string :title, default: nil
    string :description, default: nil
    string :currency, default: "TWD"

    array :questions, default: nil, strip: false do
      hash do
        integer :id, default: nil
        string :description
        string :question_type
        boolean :required, default: false
        integer :position
        array :options, default: nil do
          hash do
            integer :id, default: nil
            string :content
            integer :position
          end
        end
        array :activities, default: nil do
          hash do
            integer :id, default: nil
            string :name
            integer :position
            integer :max_participants, default: nil
            integer :price_cents, default: nil
            array :datetime_slots, default: [] do
              hash do
                integer :id, default: nil
                time :start_time
                time :end_time
                string :end_date
              end
            end
          end
        end
      end
    end

    def execute
      @survey = survey || Survey.new(
        slug: SecureRandom.uuid
      )
      @survey.assign_attributes(
        user: user,
        owner: owner,
        title: title,
        description: description
      )

      Survey.transaction do
        @survey.save!

        existing_question_ids = survey&.questions&.pluck(:id) || []
        processed_question_ids = questions.map { |question| question[:id] }

        questions.each do |question_params|
          question = @survey.questions.find_by(id: question_params[:id]) if question_params[:id].present?

          if question
            question.update!(
              description: question_params[:description],
              question_type: question_params[:question_type],
              required: question_params[:required],
              position: question_params[:position]
            )

            question.options.destroy_all if question_params[:question_type] == 'text'
          else
            question = @survey.questions.create!(
              description: question_params[:description],
              question_type: question_params[:question_type],
              required: question_params[:required],
              position: question_params[:position]
            )
          end

          if SurveyQuestion::SELECTION_TYPES.include?(question_params[:question_type])
            existing_option_ids = question.options.pluck(:id)
            processed_option_ids = []

            question_params[:options].each do |option_params|
              option = question.options.find_by(id: option_params[:id]) if option_params[:id].present?

              if option
                option.update!(content: option_params[:content], position: option_params[:position])
              else
                option = question.options.create!(content: option_params[:content], position: option_params[:position])
              end

              processed_option_ids << option.id
            end

            question.options.where(id: existing_option_ids - processed_option_ids).destroy_all
          end
        end

        questions_to_delete = @survey.questions.where(id: existing_question_ids - processed_question_ids)
        questions_to_delete.each do |question|
          question.destroy
        end

        @survey
      end
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
