# == Schema Information
#
# Table name: filtered_outcomes
#
#  id           :integer          not null, primary key
#  user_id      :integer          not null
#  filter_id    :integer
#  query        :jsonb
#  file         :string
#  page_size    :string
#  outcome_type :string
#  aasm_state   :string           not null
#  created_at   :datetime
#

class FilteredOutcome < ApplicationRecord
  EXPIRED_DAYS = 7
  OUTCOME_TYPES = %w(addresses infos).freeze
  include AASM
  mount_uploader :file, FilteredOutcomeFileUploader

  scope :active, -> { where(aasm_state: %w(processing completed)) }

  belongs_to :user
  belongs_to :filter, class_name: "QueryFilter"
  validates :outcome_type, presence: true, inclusion: { in: OUTCOME_TYPES }

  aasm :whiny_transitions => false do
    state :processing, initial: true
    state :completed, :failed, :removed

    event :complete do
      transitions from: [:processing, :failed], to: :completed
    end

    event :fail do
      transitions from: :processing, to: :failed
    end

    event :remove do
      transitions from: :completed, to: :removed
    end
  end
end
