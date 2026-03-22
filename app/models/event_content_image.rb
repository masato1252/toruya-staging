# frozen_string_literal: true

class EventContentImage < ApplicationRecord
  belongs_to :event_content

  has_one_attached :image

  validates :position, presence: true
end
