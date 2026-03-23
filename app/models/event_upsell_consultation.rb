# frozen_string_literal: true

class EventUpsellConsultation < ApplicationRecord
  belongs_to :event_content
  belongs_to :social_customer

  enum status: { waitlist: 0, confirmed: 1 }, _suffix: true

  validates :social_customer_id, uniqueness: { scope: :event_content_id }
end
