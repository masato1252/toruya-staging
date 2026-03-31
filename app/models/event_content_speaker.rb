# frozen_string_literal: true

class EventContentSpeaker < ApplicationRecord
  belongs_to :event_content

  has_one_attached :profile_image

  validates :name, presence: true
end
