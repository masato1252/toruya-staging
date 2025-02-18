# == Schema Information
#
# Table name: survey_options
#
#  id                 :bigint           not null, primary key
#  content            :string           not null
#  deleted_at         :datetime
#  position           :integer
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  survey_question_id :bigint           not null
#
# Indexes
#
#  index_survey_options_on_survey_question_id  (survey_question_id)
#
class SurveyOption < ApplicationRecord
  belongs_to :survey_question
  has_many :question_answers, dependent: :destroy

  validates :content, presence: true

  scope :active, -> { where(deleted_at: nil) }
end
