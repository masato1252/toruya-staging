# frozen_string_literal: true

class EventContentUsage < ApplicationRecord
  belongs_to :event_content
  belongs_to :event_line_user

  validates :started_at, presence: true
  validates :event_line_user_id, uniqueness: { scope: :event_content_id }
end
