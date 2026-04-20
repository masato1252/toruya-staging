# frozen_string_literal: true

# == Schema Information
#
# Table name: events
#
#  id                      :bigint           not null, primary key
#  deleted_at              :datetime
#  description             :text
#  end_at                  :datetime
#  published               :boolean          default(FALSE), not null
#  slug                    :string           not null
#  stamp_rally_description :text
#  stamp_rally_phases      :jsonb            not null
#  start_at                :datetime
#  title                   :string           not null
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  master_preview_shop_id  :bigint
#  user_id                 :bigint           not null
#
# Indexes
#
#  index_events_on_deleted_at              (deleted_at)
#  index_events_on_master_preview_shop_id  (master_preview_shop_id)
#  index_events_on_published               (published)
#  index_events_on_slug                    (slug) UNIQUE
#  index_events_on_user_id                 (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (master_preview_shop_id => shops.id)
#  fk_rails_...  (user_id => users.id)
#
class Event < ApplicationRecord
  has_many :event_contents, -> { order(:position) }, dependent: :destroy
  has_many :event_participants, dependent: :destroy
  has_many :event_activity_logs, dependent: :destroy
  has_many :event_stamp_entries, dependent: :destroy

  has_one_attached :hero_image
  has_one_attached :logo_image

  belongs_to :master_preview_shop, class_name: "Shop", optional: true

  validates :title, presence: true
  validates :slug, presence: true, uniqueness: true, format: { with: /\A[a-z0-9\-]+\z/ }

  scope :published, -> { where(published: true) }
  scope :active, -> { where(deleted_at: nil) }
  scope :undeleted, -> { where(deleted_at: nil) }

  def soft_delete!
    update!(deleted_at: Time.current)
  end

  def active?
    deleted_at.nil?
  end

  # 開催期間判定。start_at / end_at が nil の場合は「その時点の境界なし」として扱う。
  def started?
    start_at.nil? || start_at <= Time.current
  end

  def ended?
    end_at.present? && end_at < Time.current
  end

  def not_started?
    start_at.present? && start_at > Time.current
  end

  # 開催前限定プレビュー機能。
  # 「マスタ権限店舗」(event.master_preview_shop) の owner / staff であれば、
  # 開催前期間中のみ全コンテンツをプレビューできる。
  def master_previewer?(line_user)
    return false unless not_started?
    user_id = line_user&.toruya_user_id
    return false if user_id.nil?
    return false if master_preview_shop_id.nil?
    shop_member?(master_preview_shop, user_id)
  end

  # 開催前限定プレビュー機能。
  # line_user に紐づく Toruya ユーザが owner / staff である shop に
  # 紐づくコンテンツのみプレビューできる。
  def previewable_content_ids_for(line_user)
    return [] unless not_started?
    user_id = line_user&.toruya_user_id
    return [] if user_id.nil?
    shop_ids = shop_ids_for_user(user_id)
    return [] if shop_ids.empty?
    event_contents.undeleted.where(shop_id: shop_ids).pluck(:id)
  end

  # 指定 shop に紐づく集客数を集計する。
  # - direct: 参加登録時に referrer_shop_id == shop.id だった参加者数
  # - indirect: 直接参加者がさらにシェアして連れてきた参加者数 (referrer_event_line_user_id を再帰追跡)
  # - total: direct + indirect
  # 副次的な集客 (BがAをシェアで連れてくる…) は participants.referrer_event_line_user_id の連鎖を辿って計上する。
  def shop_acquisition_counts(shop_id)
    return { direct: 0, indirect: 0, total: 0 } if shop_id.blank?

    direct_user_ids = event_participants.where(referrer_shop_id: shop_id).pluck(:event_line_user_id)
    direct = direct_user_ids.size

    indirect_set = []
    visited = direct_user_ids.dup
    frontier = direct_user_ids
    while frontier.any?
      next_frontier = event_participants
                        .where(referrer_event_line_user_id: frontier)
                        .where.not(event_line_user_id: visited)
                        .pluck(:event_line_user_id)
      break if next_frontier.empty?
      indirect_set.concat(next_frontier)
      visited.concat(next_frontier)
      frontier = next_frontier
    end

    indirect = indirect_set.size
    { direct: direct, indirect: indirect, total: direct + indirect }
  end

  # スタンプラリー期間(弾)の正規化。
  # 配列要素は { title, start_on, end_on } の Hash。全項目空の行は除去する。
  # 根拠データ(event_stamp_entries)の記録は変更せず、表示/集計のみここの設定でフロント側が区切る。
  def stamp_rally_phases=(value)
    arr = Array(value).map do |row|
      h = row.respond_to?(:to_unsafe_h) ? row.to_unsafe_h : row.to_h
      h = h.with_indifferent_access
      {
        "title"    => h[:title].to_s.strip,
        "start_on" => h[:start_on].to_s.strip.presence,
        "end_on"   => h[:end_on].to_s.strip.presence
      }
    rescue StandardError
      nil
    end.compact.reject { |r| r["title"].blank? && r["start_on"].nil? && r["end_on"].nil? }

    super(arr)
  end

  private

  # user_id が owner または active staff として所属する shop_id 集合を返す。
  def shop_ids_for_user(user_id)
    owned = Shop.active.where(user_id: user_id).pluck(:id)
    staffed = Shop.active
                  .joins(:shop_staffs)
                  .joins("INNER JOIN staffs ON staffs.id = shop_staffs.staff_id")
                  .where(staffs: { user_id: user_id, deleted_at: nil })
                  .pluck(:id)
    (owned + staffed).uniq
  end

  def shop_member?(shop, user_id)
    return true if shop.user_id == user_id
    ShopStaff.joins(:staff)
             .where(shop_id: shop.id)
             .where(staffs: { user_id: user_id, deleted_at: nil })
             .exists?
  end
end
