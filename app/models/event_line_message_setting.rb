# frozen_string_literal: true

# == Schema Information
#
# Table name: event_line_message_settings
#
#  id         :bigint           not null, primary key
#  enabled    :boolean          default(TRUE), not null
#  ends_at    :datetime
#  message    :text             not null
#  position   :integer          default(0), not null
#  starts_at  :datetime         not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  event_id   :bigint           not null
#
class EventLineMessageSetting < ApplicationRecord
  belongs_to :event
  has_many :event_line_message_deliveries, dependent: :destroy

  validates :starts_at, presence: true
  validates :message, presence: true
  validate :ends_at_after_starts_at

  scope :enabled, -> { where(enabled: true) }
  scope :ordered, -> { order(:position, :starts_at, :id) }
  scope :active_at, ->(time) {
    enabled.where("starts_at <= ?", time)
           .where("ends_at IS NULL OR ends_at >= ?", time)
  }

  private

  def ends_at_after_starts_at
    return if starts_at.blank? || ends_at.blank?

    errors.add(:ends_at, "は開始日時以降にしてください") if ends_at < starts_at
  end
end
