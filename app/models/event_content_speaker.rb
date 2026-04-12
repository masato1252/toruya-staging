# frozen_string_literal: true

# == Schema Information
#
# Table name: event_content_speakers
#
#  id               :bigint           not null, primary key
#  introduction     :text
#  name             :string           not null
#  position         :integer          default(0), not null
#  position_title   :string
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  event_content_id :bigint           not null
#
# Indexes
#
#  index_event_content_speakers_on_event_content_id               (event_content_id)
#  index_event_content_speakers_on_event_content_id_and_position  (event_content_id,position)
#
# Foreign Keys
#
#  fk_rails_...  (event_content_id => event_contents.id)
#
class EventContentSpeaker < ApplicationRecord
  belongs_to :event_content

  has_one_attached :profile_image

  validates :name, presence: true
end
