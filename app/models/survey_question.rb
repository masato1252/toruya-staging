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
  has_many :options, -> { active }, dependent: :destroy, class_name: "SurveyOption"

  validates :description, presence: true
  validates :question_type, presence: true

  # You might want to add an enum for question_type
  enum question_type: {
    text: 'text',
    single_selection: 'single_selection',
    multiple_selection: 'multiple_selection',
    dropdown: 'dropdown'
  }

  scope :active, -> { where(deleted_at: nil) }
end
