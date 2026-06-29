# frozen_string_literal: true

class BackfillReferrerEventContentIdOnEventParticipants < ActiveRecord::Migration[7.0]
  def up
    say_with_time "backfill referrer_event_content_id from referrer_shop_id" do
      EventParticipant.where.not(referrer_shop_id: nil).where(referrer_event_content_id: nil).find_each do |participant|
        booth = EventContent.undeleted
                          .booth_content_type
                          .where(event_id: participant.event_id, shop_id: participant.referrer_shop_id)
                          .order(:position, :id)
                          .first
        participant.update_column(:referrer_event_content_id, booth.id) if booth
      end
    end
  end

  def down
    # 手動バックフィル分のみクリア（ボタン押下で記録された新規データは残す）
    EventParticipant.where.not(referrer_shop_id: nil).update_all(referrer_event_content_id: nil)
  end
end
