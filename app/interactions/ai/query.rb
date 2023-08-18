# frozen_string_literal: true

module Ai
  class Query < ActiveInteraction::Base
    string :user_id
    string :question

    validate :validate_question

    def execute
      response = AI_QUERY.perform(user_id, question)
      message = response.to_s
      references = response.metadata.to_h.values.map {|h| h['Source'] || h['URL'] }.uniq

      references.each do |reference|
        unless message.match?(/#{reference}/)
           message << "\n#{reference}"
        end
      end

      {
        message: message,
        references: references
      }
    end

    private

    def validate_question
      if question.blank?
        errors.add(:question, :required)
      end
    end
  end
end
