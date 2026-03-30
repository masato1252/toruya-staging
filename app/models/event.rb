# frozen_string_literal: true

class Event < ApplicationRecord
  has_many :event_contents, -> { order(:position) }, dependent: :destroy
  has_many :event_participants, dependent: :destroy
  has_many :event_activity_logs, dependent: :destroy

  validates :title, presence: true
  validates :slug, presence: true, uniqueness: true, format: { with: /\A[a-z0-9\-]+\z/ }

  scope :published, -> { where(published: true) }
  scope :active, -> { where(deleted_at: nil) }
  scope :undeleted, -> { where(deleted_at: nil) }

  def soft_delete!
    update!(deleted_at: Time.current)
  end

  def active?
    deleted_at.nil?
  end
end
