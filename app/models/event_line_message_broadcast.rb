# frozen_string_literal: true

class EventLineMessageBroadcast < ApplicationRecord
  belongs_to :event
  has_many :event_line_message_broadcast_deliveries, dependent: :destroy

  enum status: {
    pending: 0,
    delivering: 1,
    delivered: 2,
    cancelled: 3
  }, _prefix: true

  validates :scheduled_at, presence: true
  validates :message, presence: true
  validate :editable_before_delivery, on: :update

  scope :recent, -> { order(scheduled_at: :desc, id: :desc) }
  scope :due, ->(time = Time.current) { status_pending.where("scheduled_at <= ?", time) }

  STATUS_LABELS = {
    "pending" => "未配信",
    "delivering" => "配信中",
    "delivered" => "配信済み",
    "cancelled" => "取消済み"
  }.freeze

  def editable?
    status_pending?
  end

  def cancellable?
    status_pending?
  end

  def delivered_or_failed_count
    delivered_count + failed_count
  end

  def status_label
    STATUS_LABELS.fetch(status, status)
  end

  private

  def editable_before_delivery
    return if editable?
    return unless will_save_change_to_message? || will_save_change_to_scheduled_at?

    errors.add(:base, "配信開始後は編集できません")
  end
end
