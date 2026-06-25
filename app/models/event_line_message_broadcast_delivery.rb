# frozen_string_literal: true

class EventLineMessageBroadcastDelivery < ApplicationRecord
  belongs_to :event_line_message_broadcast
  belongs_to :event_line_user

  validates :event_line_user_id, uniqueness: { scope: :event_line_message_broadcast_id }
end
