# frozen_string_literal: true

# == Schema Information
#
# Table name: event_content_relations
#
#  id                       :bigint           not null, primary key
#  event_content_id         :bigint           not null
#  related_event_content_id :bigint           not null
#  position                 :integer          default(0), not null
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#
# Indexes
#
#  index_event_content_relations_on_event_content_id          (event_content_id)
#  index_event_content_relations_on_pair                      (event_content_id,related_event_content_id) UNIQUE
#  index_event_content_relations_on_related_event_content_id  (related_event_content_id)
#
# Foreign Keys
#
#  fk_rails_...  (event_content_id => event_contents.id)
#  fk_rails_...  (related_event_content_id => event_contents.id)
#
# あるコンテンツから別のコンテンツへの「関連コンテンツ」紐付けを表す中間テーブル。
# 同一イベント内のコンテンツ同士のみ紐付けられる前提（バリデーションで保証）。
class EventContentRelation < ApplicationRecord
  belongs_to :event_content
  belongs_to :related_event_content, class_name: "EventContent"

  validates :related_event_content_id,
            uniqueness: { scope: :event_content_id, message: "は既に関連付けられています" }
  validate :must_not_be_self
  validate :must_be_in_same_event

  private

  def must_not_be_self
    return unless event_content_id.present? && related_event_content_id.present?
    return unless event_content_id == related_event_content_id
    errors.add(:related_event_content_id, "は自分自身を指定できません")
  end

  def must_be_in_same_event
    return unless event_content && related_event_content
    return if event_content.event_id == related_event_content.event_id
    errors.add(:related_event_content_id, "は同じイベントのコンテンツのみ指定できます")
  end
end
