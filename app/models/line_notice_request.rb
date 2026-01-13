# frozen_string_literal: true

# == Schema Information
#
# Table name: line_notice_requests
#
#  id               :bigint           not null, primary key
#  approved_at      :datetime
#  expired_at       :datetime
#  rejected_at      :datetime
#  rejection_reason :text
#  status           :integer          default("pending"), not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  reservation_id   :bigint           not null
#  user_id          :bigint           not null
#
# Indexes
#
#  index_line_notice_requests_on_reservation_and_status  (reservation_id,status)
#  index_line_notice_requests_on_reservation_id          (reservation_id)
#  index_line_notice_requests_on_user_id                 (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (reservation_id => reservations.id)
#  fk_rails_...  (user_id => users.id)
#
class LineNoticeRequest < ApplicationRecord
  # Relations
  belongs_to :reservation
  belongs_to :user  # 店舗オーナー
  has_one :line_notice_charge, dependent: :destroy

  # Enums
  enum status: {
    pending: 0,    # リクエスト待ち
    approved: 1,   # 承認済み
    rejected: 2,   # 拒否済み
    expired: 3     # 期限切れ
  }

  # Validations
  validates :reservation_id, presence: true
  validates :user_id, presence: true
  validates :status, presence: true
  validate :no_duplicate_pending_request, on: :create

  # Callbacks
  before_create :set_default_status

  # Scopes
  scope :recent, -> { order(created_at: :desc) }
  scope :for_user, ->(user_id) { where(user_id: user_id) }
  scope :for_reservation, ->(reservation_id) { where(reservation_id: reservation_id) }

  # Instance methods
  def customer
    reservation.customers.first
  end

  def approve!
    update!(status: :approved, approved_at: Time.current)
  end

  def reject!(reason = nil)
    update!(status: :rejected, rejected_at: Time.current, rejection_reason: reason)
  end

  def expire!
    update!(status: :expired, expired_at: Time.current)
  end

  def can_be_approved?
    pending?
  end

  def can_be_rejected?
    pending?
  end

  private

  def set_default_status
    self.status ||= :pending
  end

  def no_duplicate_pending_request
    if LineNoticeRequest.pending.where(reservation_id: reservation_id).exists?
      errors.add(:reservation_id, 'already has a pending request')
    end
  end
end

