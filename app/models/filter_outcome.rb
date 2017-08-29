# == Schema Information
#
# Table name: filter_outcomes
#
#  id         :integer          not null, primary key
#  user_id    :integer          not null
#  filter_id  :integer
#  query      :jsonb
#  file       :string
#  aasm_state :string           not null
#  created_at :datetime
#

class FilterOutcome < ApplicationRecord
  include AASM
  mount_uploader :file, FilterOutcomeFileUploader

  scope :active, -> { where.not(aasm_state: "deleted") }

  belongs_to :user

  aasm :whiny_transitions => false do
    state :processing, initial: true
    state :completed, :failed, :deleted

    event :process do
      transitions from: [:pending], to: :processing
    end

    event :complete do
      transitions from: :processing, to: :completed
    end

    event :fail do
      transitions from: :processing, to: :failed
    end

    event :delete do
      transitions from: :completed, to: :deleted
    end
  end
end
