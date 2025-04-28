# == Schema Information
#
# Table name: survey_questions
#
#  id            :bigint           not null, primary key
#  deleted_at    :datetime
#  description   :text             not null
#  position      :integer
#  question_type :string           not null
#  required      :boolean          default(FALSE)
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  survey_id     :bigint           not null
#
# Indexes
#
#  index_survey_questions_on_survey_id  (survey_id)
#
class SurveyQuestion < ApplicationRecord
  SELECTION_TYPES = %w[single_selection multiple_selection dropdown].freeze

  belongs_to :survey
  has_many :options, class_name: "SurveyOption"
  has_many :activities, class_name: "SurveyActivity"

  validates :description, presence: true
  validates :question_type, presence: true
  validate :validate_activity_question_uniqueness, if: -> { activity? }

  # 1 survey could only have 1 activity question
  # 1 survey question can have multiple activities
  # 1 activity had multiple date
  # 1 activity had 1 quantity
  # 1 survey had 1 quanity question, that take the quantity of the activity
  # 1 reservation customer bind to 1 activity
  # 1 reservation customer can have 1 survey response
  # 1 reservation customer had new quantity column to keep the quantity when they reply the survey
  enum question_type: {
    text: 'text',
    single_selection: 'single_selection',
    multiple_selection: 'multiple_selection',
    dropdown: 'dropdown',
    image: 'image',
    activity: 'activity',
    quantity: 'quantity',
    empty_block: 'empty_block' # only for user fillin the information
  }

  scope :active, -> { where(deleted_at: nil) }

  private

  def validate_activity_question_uniqueness
    return unless survey

    existing_activity_question = survey.questions.active.where(question_type: :activity)
    if existing_activity_question.exists? && existing_activity_question.first.id != id
      errors.add(:question_type, "only one activity question is allowed per survey")
    end
  end
end
