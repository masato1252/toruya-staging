# frozen_string_literal: true

# == Schema Information
#
# Table name: event_activity_logs
#
#  id                 :bigint           not null, primary key
#  activity_type      :integer          not null
#  metadata           :jsonb
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  event_content_id   :bigint           not null
#  event_id           :bigint           not null
#  event_line_user_id :bigint           not null
#
# Indexes
#
#  idx_evt_activity_logs_content_type               (event_content_id,activity_type)
#  idx_evt_activity_logs_user_type                  (event_line_user_id,activity_type)
#  index_event_activity_logs_on_event_content_id    (event_content_id)
#  index_event_activity_logs_on_event_id            (event_id)
#  index_event_activity_logs_on_event_line_user_id  (event_line_user_id)
#
# Foreign Keys
#
#  fk_rails_...  (event_content_id => event_contents.id)
#  fk_rails_...  (event_id => events.id)
#  fk_rails_...  (event_line_user_id => event_line_users.id)
#
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
