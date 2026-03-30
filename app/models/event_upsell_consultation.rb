# frozen_string_literal: true

class EventUpsellConsultation < ApplicationRecord
  belongs_to :event_content
  belongs_to :event_line_user

  enum status: { waitlist: 0, confirmed: 1 }, _suffix: true

  validates :event_line_user_id, uniqueness: { scope: :event_content_id }
end
