# frozen_string_literal: true

class EventContentDocument < ApplicationRecord
  belongs_to :event_content

  validates :title, presence: true
  validates :url, presence: true
  validates :url, format: {
    with: %r{\Ahttps?://}i,
    message: "は http:// または https:// で始まるURLを入力してください"
  }
end
