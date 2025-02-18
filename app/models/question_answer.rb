# == Schema Information
#
# Table name: question_answers
#
#  id                       :bigint           not null, primary key
#  survey_option_snapshot   :text
#  survey_question_snapshot :text             not null
#  text_answer              :text
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  survey_option_id         :bigint
#  survey_question_id       :bigint           not null
#  survey_response_id       :bigint           not null
#
# Indexes
#
#  index_question_answers_on_survey_option_id    (survey_option_id)
#  index_question_answers_on_survey_question_id  (survey_question_id)
#  index_question_answers_on_survey_response_id  (survey_response_id)
#
class QuestionAnswer < ApplicationRecord
  belongs_to :survey_response
  belongs_to :survey_question
  belongs_to :survey_option, optional: true # Optional because text questions don't need an option

  validate :answer_format_matches_question_type

  private

  def answer_format_matches_question_type
    case survey_question.question_type
    when 'text'
      errors.add(:survey_option, 'should be blank for text questions') if survey_option.present?
      errors.add(:text_answer, 'cannot be blank for text questions') if text_answer.blank?
    when 'single_selection'
      errors.add(:survey_option, 'must be present for single selection questions') if survey_option.blank?
      errors.add(:text_answer, 'should be blank for single selection questions') if text_answer.present?
    when 'multiple_selection'
      errors.add(:survey_option, 'must be present for multiple selection questions') if survey_option.blank?
      errors.add(:text_answer, 'should be blank for multiple selection questions') if text_answer.present?
    end
  end
end
