module Surveys
  class Upsert < ActiveInteraction::Base
    object :user
    object :owner, class: ApplicationRecord # ReservationCustomer or Customer
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

      # Track slots that were deleted during this update
      deleted_slot_ids = []

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

            # If question type is changed to text or activity, delete all options and activities that have no responses
            question.options.destroy_all if question_params[:question_type] == 'text' || question_params[:question_type] == 'activity'
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
          elsif question_params[:question_type] == 'activity'
            existing_activity_ids = question.activities.pluck(:id)
            processed_activity_ids = []

            question_params[:activities].each do |activity_params|
              activity = question.activities.find_by(id: activity_params[:id]) if activity_params[:id].present?

              if activity
                activity.update!(
                  name: activity_params[:name],
                  position: activity_params[:position],
                  max_participants: activity_params[:max_participants],
                  price_cents: activity_params[:price_cents],
                  currency: currency
                )
              else
                activity = question.activities.create!(
                  survey: @survey,
                  name: activity_params[:name],
                  position: activity_params[:position],
                  max_participants: activity_params[:max_participants],
                  price_cents: activity_params[:price_cents],
                  currency: currency
                )
              end

              processed_activity_ids << activity.id

              existing_slot_ids = activity.activity_slots.pluck(:id)
              processed_slot_ids = []

              activity_params[:datetime_slots].each do |slot_params|
                slot = activity.activity_slots.find_by(id: slot_params[:id]) if slot_params[:id].present?

                if slot
                  slot.update!(start_time: slot_params[:start_time], end_time: slot_params[:end_time])
                else
                  slot = activity.activity_slots.create!(
                    start_time: slot_params[:start_time],
                    end_time: slot_params[:end_time]
                  )
                end

                compose(SurveyActivitySlots::UpsertReservation,
                  survey: @survey,
                  activity: activity,
                  slot: slot,
                  customer: nil,
                  survey_response: nil
                )

                activity.survey_responses.each do |response|
                  compose(SurveyActivitySlots::UpsertReservation,
                    survey: @survey,
                    activity: activity,
                    slot: slot,
                    customer: response.owner,
                    survey_response: response
                  )
                end

                processed_slot_ids << slot.id
              end

              deleted_slot_ids.concat(existing_slot_ids - processed_slot_ids)
              activity.activity_slots.where(id: existing_slot_ids - processed_slot_ids).destroy_all
            end
          end
        end

        # handle deleted questions
        questions_to_delete = @survey.questions.where(id: existing_question_ids - processed_question_ids)
        questions_to_delete.each do |question|
          question.activities.each do |activity|
            activity.destroy if !activity.survey_responses.any?
          end
          question.destroy
        end

        # handle deleted slots
        if deleted_slot_ids.any?
          Reservation.where(survey_activity_slot_id: deleted_slot_ids).destroy_all
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

        if question[:question_type] == 'activity' && question[:activities].blank?
          errors.add(:questions, "Question #{index + 1} requires at least one activity")
        end

        if question[:question_type] == 'activity'
          question[:activities].each_with_index do |activity, activity_index|
            if activity[:datetime_slots].blank?
              errors.add(:questions, "Activity #{activity_index + 1} in question #{index + 1} requires at least one datetime slot")
            end
          end
        end
      end
    end
  end
end
