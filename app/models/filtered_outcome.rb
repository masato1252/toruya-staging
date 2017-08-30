# == Schema Information
#
# Table name: filtered_outcomes
#
#  id         :integer          not null, primary key
#  user_id    :integer          not null
#  filter_id  :integer
#  query      :jsonb
#  file       :string
#  aasm_state :string           not null
#  created_at :datetime
#

class FilteredOutcome < ApplicationRecord
  include AASM
  mount_uploader :file, FilterOutcomeFileUploader

  scope :active, -> { where.not(aasm_state: "deleted") }

  belongs_to :user
  belongs_to :filter, class_name: "QueryFilter"

  aasm :whiny_transitions => false do
    state :processing, initial: true
    state :completed, :failed, :removed

    event :process do
      transitions from: [:pending], to: :processing
    end

    event :complete do
      transitions from: :processing, to: :completed
    end

    event :fail do
      transitions from: :processing, to: :failed
    end

    event :remove do
      transitions from: :completed, to: :removed
    end
  end
end
