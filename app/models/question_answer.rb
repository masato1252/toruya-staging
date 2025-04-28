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
#  survey_activity_id       :bigint
#  survey_option_id         :bigint
#  survey_question_id       :bigint           not null
#  survey_response_id       :bigint           not null
#
# Indexes
#
#  index_question_answers_on_survey_activity_id  (survey_activity_id)
#  index_question_answers_on_survey_option_id    (survey_option_id)
#  index_question_answers_on_survey_question_id  (survey_question_id)
#  index_question_answers_on_survey_response_id  (survey_response_id)
#
class QuestionAnswer < ApplicationRecord
  belongs_to :survey_response
  belongs_to :survey_question
  belongs_to :survey_option, optional: true # Optional because text questions don't need an option
  belongs_to :survey_activity, optional: true # Optional because only activity questions need this
  belongs_to :survey_activity_slot, optional: true # Optional because only activity questions need this

  validate :answer_format_matches_question_type
  alias_attribute :survey_activity_snapshot, :survey_option_snapshot

  def answer_set
  end

  private

  def answer_format_matches_question_type
    case survey_question.question_type
    when 'text'
      errors.add(:survey_option, 'should be blank for text questions') if survey_option.present?
      errors.add(:survey_activity, 'should be blank for text questions') if survey_activity.present?
      errors.add(:text_answer, 'cannot be blank for text questions') if text_answer.blank?
    when 'single_selection'
      errors.add(:survey_option, 'must be present for single selection questions') if survey_option.blank?
      errors.add(:survey_activity, 'should be blank for single selection questions') if survey_activity.present?
      errors.add(:text_answer, 'should be blank for single selection questions') if text_answer.present?
    when 'multiple_selection'
      errors.add(:survey_option, 'must be present for multiple selection questions') if survey_option.blank?
      errors.add(:survey_activity, 'should be blank for multiple selection questions') if survey_activity.present?
      errors.add(:text_answer, 'should be blank for multiple selection questions') if text_answer.present?
    when 'activity'
      errors.add(:survey_option, 'should be blank for activity questions') if survey_option.present?
      errors.add(:survey_activity, 'must be present for activity questions') if survey_activity.blank?
      errors.add(:text_answer, 'should be blank for activity questions') if text_answer.present?
    end
  end
end
