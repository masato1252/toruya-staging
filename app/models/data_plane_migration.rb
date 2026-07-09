# frozen_string_literal: true

# Records owners whose business data plane is Supabase (v1 compat) instead of legacy AR.
class DataPlaneMigration < ApplicationRecord
  ACTIVE_STATUSES = %w[completed record_only].freeze

  validates :user_id, presence: true, uniqueness: true
  validates :migrated_at, presence: true
  validates :status, presence: true, inclusion: { in: ACTIVE_STATUSES + %w[failed] }
  validates :source, presence: true

  scope :active, -> { where(rolled_back_at: nil, status: ACTIVE_STATUSES) }

  def self.migrated?(user_id)
    return false if user_id.blank?

    active.exists?(user_id: user_id)
  end

  def self.record!(user_id:, status: "completed", source: "job", metadata: {})
    now = Time.current
    record = find_or_initialize_by(user_id: user_id)
    record.assign_attributes(
      migrated_at: now,
      status: status,
      source: source,
      metadata: metadata,
      rolled_back_at: nil,
      updated_at: now
    )
    record.created_at ||= now
    record.save!
    record
  end
end
