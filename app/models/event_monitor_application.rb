# frozen_string_literal: true

class EventMonitorApplication < ApplicationRecord
  belongs_to :event_content
  belongs_to :social_customer

  validates :social_customer_id, uniqueness: { scope: :event_content_id }
end
