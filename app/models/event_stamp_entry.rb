# frozen_string_literal: true

# == Schema Information
#
# Table name: event_stamp_entries
#
#  id                 :bigint           not null, primary key
#  action_type        :integer          not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  event_content_id   :bigint           not null
#  event_id           :bigint           not null
#  event_line_user_id :bigint           not null
#
# Indexes
#
#  idx_stamp_entries_unique_action                  (event_line_user_id,event_content_id,action_type) UNIQUE
#  index_event_stamp_entries_on_event_content_id    (event_content_id)
#  index_event_stamp_entries_on_event_id            (event_id)
#  index_event_stamp_entries_on_event_line_user_id  (event_line_user_id)
#
# Foreign Keys
#
#  fk_rails_...  (event_content_id => event_contents.id)
#  fk_rails_...  (event_id => events.id)
#  fk_rails_...  (event_line_user_id => event_line_users.id)
#
class EventStampEntry < ApplicationRecord
  belongs_to :event
  belongs_to :event_content
  belongs_to :event_line_user

  enum action_type: {
    material_download: 0,
    seminar_view: 1,
    upsell_consultation: 2,
    monitor_apply: 3
  }

  validates :action_type, presence: true
  validates :event_line_user_id, uniqueness: { scope: [:event_content_id, :action_type] }

  ACTION_LABELS = {
    "material_download" => "資料DL",
    "seminar_view"      => "セミナー",
    "upsell_consultation" => "相談予約",
    "monitor_apply"     => "モニター"
  }.freeze

  def self.compute_tickets(entries)
    grouped = entries.group_by(&:action_type)
    downloads = (grouped["material_download"]&.size || 0) / 3
    seminars  = (grouped["seminar_view"]&.size || 0) / 3
    consults  = grouped["upsell_consultation"]&.size || 0
    monitors  = grouped["monitor_apply"]&.size || 0
    downloads + seminars + consults + monitors
  end

  def label
    ACTION_LABELS[action_type] || action_type
  end
end
