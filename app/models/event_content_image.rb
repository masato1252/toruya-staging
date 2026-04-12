# frozen_string_literal: true

# == Schema Information
#
# Table name: event_content_images
#
#  id               :bigint           not null, primary key
#  position         :integer          default(0), not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  event_content_id :bigint           not null
#
# Indexes
#
#  index_event_content_images_on_event_content_id               (event_content_id)
#  index_event_content_images_on_event_content_id_and_position  (event_content_id,position)
#
# Foreign Keys
#
#  fk_rails_...  (event_content_id => event_contents.id)
#
class EventContentImage < ApplicationRecord
  belongs_to :event_content

  has_one_attached :image

  validates :position, presence: true
end
