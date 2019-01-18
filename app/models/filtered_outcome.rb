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
#  name         :string
#
# Indexes
#
#  filtered_outcome_index              (user_id,aasm_state,outcome_type,created_at)
#  index_filtered_outcomes_on_user_id  (user_id)
#

class FilteredOutcome < ApplicationRecord
  EXPIRED_DAYS = 7
  CUSTOMERS_OUTCOME_TYPES = %w(addresses infos).freeze
  RESERVATIONS_OUTCOME_TYPES = %w(reservation_infos).freeze
  OUTCOME_TYPES = CUSTOMERS_OUTCOME_TYPES + RESERVATIONS_OUTCOME_TYPES
  include AASM
  mount_uploader :file, FilteredOutcomeFileUploader

  scope :active, -> { where(aasm_state: %w(processing completed)) }
  scope :customers, -> { where(outcome_type: CUSTOMERS_OUTCOME_TYPES) }
  scope :reservations, -> { where(outcome_type: RESERVATIONS_OUTCOME_TYPES) }

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
