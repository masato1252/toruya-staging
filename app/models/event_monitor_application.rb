# frozen_string_literal: true

class EventMonitorApplication < ApplicationRecord
  belongs_to :event_content
  belongs_to :social_user

  validates :social_user_id, uniqueness: { scope: :event_content_id }
end
