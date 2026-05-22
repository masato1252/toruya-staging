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

  # 下書き(status=0)コンテンツのプレビュー権限。
  # 「マスタ権限店舗」(event.master_preview_shop) の owner / staff であれば、
  # 開催期間に関わらず、すべての下書きコンテンツを一覧/詳細で閲覧できる。
  def master_previewer?(line_user)
    user_id = line_user&.toruya_user_id
    return false if user_id.nil?
    return false if master_preview_shop_id.nil?
    shop_member?(master_preview_shop, user_id)
  end

  # 下書き(status=0)コンテンツのプレビュー権限。
  # line_user に紐づく Toruya ユーザが owner / staff である shop に
  # 紐づく下書きコンテンツの ID 配列を返す。
  # 公開コンテンツは誰でも見られるため、ここには含めない。
  def previewable_content_ids_for(line_user)
    user_id = line_user&.toruya_user_id
    return [] if user_id.nil?
    shop_ids = shop_ids_for_user(user_id)
    return [] if shop_ids.empty?
    event_contents.undeleted.status_unpublished.where(shop_id: shop_ids).pluck(:id)
  end

  # 公開ページで viewer が閲覧できる event_contents の Relation を返す。
  # - 未ログイン / 通常ユーザ: 公開コンテンツのみ
  # - 出展店舗 owner/staff: 公開コンテンツ + 自店舗の下書き
  # - マスタプレビュー店舗 owner/staff: 全コンテンツ (公開 + 全下書き)
  def visible_event_contents_for(line_user)
    base = event_contents.undeleted
    return base.status_published if line_user.nil?
    return base if master_previewer?(line_user)

    draft_ids = previewable_content_ids_for(line_user)
    return base.status_published if draft_ids.empty?
    base.where("event_contents.status = ? OR event_contents.id IN (?)", EventContent.statuses[:published], draft_ids)
  end

  # マスタプレビュー / 出展店舗プレビュー権限を持つ参加者（内部・関係者）。
  def preview_insider?(line_user)
    return false if line_user.nil? || line_user.toruya_user_id.nil?

    master_previewer?(line_user) || previewable_content_ids_for(line_user).any?
  end

  # 解析・集客表示から除外する event_line_user_id 一覧（参加登録済みのプレビュー権限者のみ）。
  def analytics_excluded_event_line_user_ids
    @analytics_excluded_event_line_user_ids ||= begin
      event_participants.includes(:event_line_user).filter_map do |participant|
        elu = participant.event_line_user
        elu.id if preview_insider?(elu)
      end.uniq
    end
  end

  def analytics_participants_count
    excluded = analytics_excluded_event_line_user_ids
    scope = event_participants
    excluded.any? ? scope.where.not(event_line_user_id: excluded).count : scope.count
  end

  def analytics_activity_logs
    scope = event_activity_logs
    excluded = analytics_excluded_event_line_user_ids
    excluded.any? ? scope.where.not(event_line_user_id: excluded) : scope
  end

  # Ahoy のコンテンツ閲覧イベント（プレビュー権限者を除外した表示用）。
  def ahoy_content_views(content_id)
    scope = Ahoy::Event.where(name: "event_content_view")
                       .where("properties->>'event_content_id' = ?", content_id.to_s)
    excluded = analytics_excluded_event_line_user_ids
    return scope if excluded.empty?

    scope.where.not("properties->>'event_line_user_id' IN (?)", excluded.map(&:to_s))
  end

  # 指定 shop に紐づく集客数を集計する。
  # - direct: 参加登録時に referrer_shop_id == shop.id だった参加者数
  # - indirect: 直接参加者がさらにシェアして連れてきた参加者数 (referrer_event_line_user_id を再帰追跡)
  # - total: direct + indirect
  # プレビュー権限者は内部関係者のため人数から除外する。
  def shop_acquisition_counts(shop_id)
    return { direct: 0, indirect: 0, total: 0 } if shop_id.blank?

    excluded = analytics_excluded_event_line_user_ids

    direct_scope = event_participants.where(referrer_shop_id: shop_id)
    direct_scope = direct_scope.where.not(event_line_user_id: excluded) if excluded.any?
    direct_user_ids = direct_scope.pluck(:event_line_user_id)
    direct = direct_user_ids.size

    indirect_set = []
    visited = direct_user_ids.dup
    frontier = direct_user_ids
    while frontier.any?
      next_scope = event_participants
                     .where(referrer_event_line_user_id: frontier)
                     .where.not(event_line_user_id: visited)
      next_scope = next_scope.where.not(event_line_user_id: excluded) if excluded.any?
      next_frontier = next_scope.pluck(:event_line_user_id)
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

  # user_id が owner / staff(staffs.user_id) / 管理者ログイン(staff_accounts.user_id) として所属する shop_id 集合を返す。
  # Toruya の管理者は staffs.user_id が店舗オーナー側のまま、実際の LINE ログインは staff_accounts.user_id に紐づく。
  def shop_ids_for_user(user_id)
    owned = Shop.active.where(user_id: user_id).pluck(:id)
    staffed = Shop.active
                  .joins(:shop_staffs)
                  .joins("INNER JOIN staffs ON staffs.id = shop_staffs.staff_id")
                  .where(staffs: { user_id: user_id, deleted_at: nil })
                  .pluck(:id)
    account_staffed = Shop.active
                          .joins(shop_staffs: { staff: :staff_account })
                          .merge(StaffAccount.active)
                          .where(staff_accounts: { user_id: user_id })
                          .where(staffs: { deleted_at: nil })
                          .pluck(:id)
    (owned + staffed + account_staffed).uniq
  end

  def shop_member?(shop, user_id)
    return true if shop.user_id == user_id
    return true if ShopStaff.joins(:staff)
                            .where(shop_id: shop.id)
                            .where(staffs: { user_id: user_id, deleted_at: nil })
                            .exists?
    StaffAccount.active
                .joins(staff: :shop_staffs)
                .where(user_id: user_id, shop_staffs: { shop_id: shop.id })
                .joins("INNER JOIN staffs ON staffs.id = shop_staffs.staff_id")
                .where(staffs: { deleted_at: nil })
                .exists?
  end
end
