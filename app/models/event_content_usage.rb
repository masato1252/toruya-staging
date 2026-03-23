# frozen_string_literal: true

class EventContentUsage < ApplicationRecord
  belongs_to :event_content
  belongs_to :social_customer

  validates :started_at, presence: true
  validates :social_customer_id, uniqueness: { scope: :event_content_id }
end
