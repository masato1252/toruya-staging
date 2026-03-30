# frozen_string_literal: true

class EventActivityLog < ApplicationRecord
  belongs_to :event
  belongs_to :event_content
  belongs_to :event_line_user

  enum activity_type: {
    seminar_view: 0,
    material_download: 1,
    online_service_click: 2,
    upsell_click: 3
  }

  validates :activity_type, presence: true
end
