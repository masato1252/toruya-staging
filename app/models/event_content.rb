# frozen_string_literal: true

class EventContent < ApplicationRecord
  belongs_to :event
  belongs_to :shop, optional: true
  belongs_to :online_service, optional: true
  belongs_to :upsell_booking_page, class_name: "BookingPage", optional: true

  has_many :event_content_images, -> { order(:position) }, dependent: :destroy
  has_many :event_content_usages, dependent: :destroy
  has_many :event_upsell_consultations, dependent: :destroy
  has_many :event_monitor_applications, dependent: :destroy

  has_one_attached :thumbnail

  enum content_type: { seminar: 0, booth: 1 }, _suffix: true

  validates :title, presence: true

  scope :undeleted, -> { where(deleted_at: nil) }
  scope :active, -> { where(deleted_at: nil) }

  def soft_delete!
    update!(deleted_at: Time.current)
  end

  def started?
    start_at.present? && start_at <= Time.current
  end

  def ended?
    end_at.present? && end_at < Time.current
  end

  def usage_count
    event_content_usages.count
  end

  def capacity_full?
    capacity.present? && usage_count >= capacity
  end

  def consultation_count
    event_upsell_consultations.where(status: :confirmed).count
  end

  def consultation_full?
    return false unless upsell_booking_enabled?
    # capacity of booking page is checked separately via booking_page
    false
  end
end
