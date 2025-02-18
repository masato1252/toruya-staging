# == Schema Information
#
# Table name: surveys
#
#  id          :bigint           not null, primary key
#  active      :boolean          default(TRUE)
#  description :text
#  owner_type  :string
#  scenario    :string
#  title       :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  owner_id    :bigint
#  user_id     :bigint           not null
#
# Indexes
#
#  index_surveys_on_owner    (owner_type,owner_id)
#  index_surveys_on_user_id  (user_id)
#
class Survey < ApplicationRecord
  belongs_to :user
  belongs_to :owner, polymorphic: true, optional: true

  has_many :questions, -> { active }, dependent: :destroy, class_name: "SurveyQuestion"
  has_many :responses, dependent: :destroy, class_name: "SurveyResponse"

  scope :active, -> { where(deleted_at: nil) }
end
