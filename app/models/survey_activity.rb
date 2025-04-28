# == Schema Information
#
# Table name: survey_activities
#
#  id                 :bigint           not null, primary key
#  currency           :string
#  max_participants   :integer
#  name               :string           not null
#  position           :integer
#  price_cents        :integer
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  survey_id          :bigint
#  survey_question_id :bigint           not null
#
# Indexes
#
#  index_survey_activities_on_survey_id           (survey_id)
#  index_survey_activities_on_survey_question_id  (survey_question_id)
#
class SurveyActivity < ApplicationRecord
  belongs_to :survey_question
  belongs_to :survey
  has_many :activity_slots, class_name: "SurveyActivitySlot"
  has_many :reservations, dependent: :destroy
  has_many :survey_responses, dependent: :destroy
  has_many :broadcasts, as: :builder, dependent: :destroy

  validates :name, presence: true
  validates :max_participants, numericality: { only_integer: true, greater_than_or_equal_to: 0, allow_nil: true }
  validates :price_cents, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :currency, presence: true
end
