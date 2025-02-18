# == Schema Information
#
# Table name: survey_responses
#
#  id         :bigint           not null, primary key
#  owner_type :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  owner_id   :bigint
#  survey_id  :bigint           not null
#
# Indexes
#
#  index_survey_responses_on_owner      (owner_type,owner_id)
#  index_survey_responses_on_survey_id  (survey_id)
#
class SurveyResponse < ApplicationRecord
  belongs_to :survey
  belongs_to :owner, polymorphic: true
  has_many :question_answers, dependent: :destroy

  validates :owner, presence: true
end
