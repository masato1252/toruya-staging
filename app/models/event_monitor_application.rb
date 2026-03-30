# frozen_string_literal: true

class EventMonitorApplication < ApplicationRecord
  belongs_to :event_content
  belongs_to :event_line_user

  validates :event_line_user_id, uniqueness: { scope: :event_content_id }
end
