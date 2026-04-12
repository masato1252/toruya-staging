# frozen_string_literal: true

# == Schema Information
#
# Table name: events
#
#  id          :bigint           not null, primary key
#  deleted_at  :datetime
#  description :text
#  end_at      :datetime
#  published   :boolean          default(FALSE), not null
#  slug        :string           not null
#  start_at    :datetime
#  title       :string           not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  user_id     :bigint           not null
#
# Indexes
#
#  index_events_on_deleted_at  (deleted_at)
#  index_events_on_published   (published)
#  index_events_on_slug        (slug) UNIQUE
#  index_events_on_user_id     (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
class Event < ApplicationRecord
  has_many :event_contents, -> { order(:position) }, dependent: :destroy
  has_many :event_participants, dependent: :destroy
  has_many :event_activity_logs, dependent: :destroy

  has_one_attached :hero_image

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
