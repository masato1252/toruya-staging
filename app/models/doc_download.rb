# frozen_string_literal: true

class DocDownload < ApplicationRecord
  belongs_to :doc
  belongs_to :doc_line_user

  validates :doc_line_user_id, uniqueness: { scope: :doc_id }

  def record_visit!(referrer: nil)
    self.first_visited_at ||= Time.current
    self.referrer ||= referrer.presence
    save! if changed?
  end

  def record_download!(referrer: nil)
    now = Time.current
    self.first_visited_at ||= now
    self.first_downloaded_at ||= now
    self.referrer ||= referrer.presence
    self.download_count += 1
    save!
  end
end
