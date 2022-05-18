# == Schema Information
#
# Table name: custom_messages
#
#  id           :bigint           not null, primary key
#  after_days   :integer
#  content      :text             not null
#  receiver_ids :string           default([]), is an Array
#  scenario     :string           not null
#  service_type :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  service_id   :bigint
#
# Indexes
#
#  sequence_message_index  (service_type,service_id,scenario,after_days)
#

require "translator"
require "line_client"

# When service is nil, that's toruya's custom message

class CustomMessage < ApplicationRecord
  scope :scenario_of, -> (service, scenario) { where(service: service, scenario: scenario) }
  scope :right_away, -> { where(after_days: nil) }
  scope :sequence, -> { where.not(after_days: nil) }
  validates :service_type, inclusion: { in: %w(OnlineService BookingPage) }, allow_nil: true

  belongs_to :service, polymorphic: true, optional: true # OnlineService, BookingPage or nil(Toruya user)

  has_one_attached :picture # content picture

  def demo_message_content
    Translator.perform(content, service.message_template_variables(service.user))
  end

  def demo_message_for_owner
    LineClient.send(service.user.social_user, demo_message_content)
  end
end
