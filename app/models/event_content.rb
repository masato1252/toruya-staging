# frozen_string_literal: true

# == Schema Information
#
# Table name: event_contents
#
#  id                     :bigint           not null, primary key
#  capacity               :integer
#  content_type           :integer          default("seminar"), not null
#  deleted_at             :datetime
#  description            :text
#  direct_download_url    :string
#  end_at                 :datetime
#  exhibitor_company_name :string
#  exhibitor_description  :text
#  exhibitor_roles        :jsonb            not null
#  introduction           :text
#  monitor_enabled        :boolean          default(FALSE), not null
#  monitor_form_url       :string
#  monitor_limit          :integer
#  monitor_name           :string
#  monitor_price          :integer
#  position               :integer          default(0), not null
#  post_ad_video_url      :string
#  pre_ad_video_url       :string
#  start_at               :datetime
#  status                 :integer          default(1), not null
#  title                  :string           not null
#  upsell_booking_enabled :boolean          default(FALSE), not null
#  video_url              :string
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  event_id               :bigint           not null
#  online_service_id      :bigint
#  shop_id                :bigint
#  upsell_booking_page_id :bigint
#
# Indexes
#
#  index_event_contents_on_deleted_at              (deleted_at)
#  index_event_contents_on_event_id                (event_id)
#  index_event_contents_on_event_id_and_position   (event_id,position)
#  index_event_contents_on_online_service_id       (online_service_id)
#  index_event_contents_on_shop_id                 (shop_id)
#  index_event_contents_on_status                  (status)
#  index_event_contents_on_upsell_booking_page_id  (upsell_booking_page_id)
#
# Foreign Keys
#
#  fk_rails_...  (event_id => events.id)
#  fk_rails_...  (online_service_id => online_services.id)
#  fk_rails_...  (shop_id => shops.id)
#  fk_rails_...  (upsell_booking_page_id => booking_pages.id)
#
class EventContent < ApplicationRecord
  belongs_to :event
  belongs_to :shop, optional: true
  belongs_to :online_service, optional: true
  belongs_to :upsell_booking_page, class_name: "BookingPage", optional: true

  has_many :event_content_images, -> { order(:position) }, dependent: :destroy
  has_many :event_content_speakers, -> { order(:position) }, dependent: :destroy
  has_many :event_content_usages, dependent: :destroy
  has_many :event_upsell_consultations, dependent: :destroy
  has_many :event_monitor_applications, dependent: :destroy
  has_many :event_activity_logs, dependent: :destroy
  has_many :event_stamp_entries, dependent: :destroy

  # 関連コンテンツ（このコンテンツ → 別コンテンツへの紐付け）。
  has_many :event_content_relations,
           -> { order(:position) },
           foreign_key: :event_content_id,
           dependent: :destroy
  has_many :related_event_contents,
           through: :event_content_relations,
           source: :related_event_content
  # 逆方向参照（このコンテンツが他から関連付けられている関係）。削除時に整理するためのみ使用。
  has_many :inverse_event_content_relations,
           class_name: "EventContentRelation",
           foreign_key: :related_event_content_id,
           dependent: :destroy

  has_one_attached :thumbnail
  has_one_attached :exhibitor_logo

  enum content_type: { seminar: 0, booth: 1 }, _suffix: true
  # status=0 を下書き/非公開、status=1 を公開とする。
  # 公開側 (events#show / event_contents#show / EventSerializer) では published のみを表示する。
  enum status: { unpublished: 0, published: 1 }, _prefix: :status

  validates :title, presence: true
  validates :exhibitor_company_name, presence: true, if: :booth_content_type?

  scope :undeleted, -> { where(deleted_at: nil) }
  scope :active, -> { where(deleted_at: nil) }

  def soft_delete!
    update!(deleted_at: Time.current)
  end

  # 親イベントの開催期間でコンテンツ公開期間を強制クランプする。
  # - 開催前 (event.not_started?) → started? = false (「公開開始前」扱い)
  # - 開催終了後 (event.ended?)   → ended?   = true  (「配信終了」扱い)
  def started?
    return false if event.not_started?
    start_at.present? && start_at <= Time.current
  end

  def ended?
    return true if event.ended?
    end_at.present? && end_at < Time.current
  end

  # 表示用の「実際に公開が始まる / 終わる」日時。
  # event 側が nil (= 境界なし) の場合はクランプしない。
  def effective_start_at
    return start_at if event.start_at.nil?
    return event.start_at if start_at.nil?
    [event.start_at, start_at].max
  end

  def effective_end_at
    return end_at if event.end_at.nil?
    return event.end_at if end_at.nil?
    [event.end_at, end_at].min
  end

  def usage_count
    event_content_usages.count
  end

  # 解析表示用（プレビュー権限者を除外）。
  def analytics_usage_count
    scope = event_content_usages
    excluded = event.analytics_excluded_event_line_user_ids
    excluded.any? ? scope.where.not(event_line_user_id: excluded).count : scope.count
  end

  def analytics_upsell_consultations_count
    scope = event_upsell_consultations
    excluded = event.analytics_excluded_event_line_user_ids
    excluded.any? ? scope.where.not(event_line_user_id: excluded).count : scope.count
  end

  def analytics_monitor_applications_count
    scope = event_monitor_applications
    excluded = event.analytics_excluded_event_line_user_ids
    excluded.any? ? scope.where.not(event_line_user_id: excluded).count : scope.count
  end

  # 展示ブースの「参加登録」ボタン経由（または過去データの shop 紐付け）での参加登録数。
  def analytics_registration_count
    return 0 unless booth_content_type?

    scope = event.event_participants.where(referrer_event_content_id: id)
    excluded = event.analytics_excluded_event_line_user_ids
    excluded.any? ? scope.where.not(event_line_user_id: excluded).count : scope.count
  end

  def capacity_full?
    capacity.present? && usage_count >= capacity
  end

  def consultation_count
    event_upsell_consultations.where(status: :confirmed).count
  end

  def consultation_full?
    return false unless upsell_booking_enabled?
    # capacity of booking page is checked separately via booking_page
    false
  end

  # フォームから [related_content_ids: [id1, id2, ...]] で受け取る用の getter。
  def related_content_ids
    event_content_relations.order(:position).pluck(:related_event_content_id)
  end

  # フォームから受け取った id 配列で event_content_relations を同期する。
  # - 自身の id, 空文字, 重複は除外
  # - 同じイベント内のコンテンツのみを対象とする
  # - 並び順は配列の順番をそのまま position として保存する
  def related_content_ids=(ids)
    cleaned = Array(ids)
              .map { |v| v.to_s.strip }
              .reject(&:blank?)
              .map(&:to_i)
              .reject { |id| id == self.id }
              .uniq

    if persisted?
      sync_related_content_ids(cleaned)
    else
      @pending_related_content_ids = cleaned
    end
  end

  # 新規作成時は after_save で同期する。
  after_save :persist_pending_related_content_ids, if: -> { @pending_related_content_ids }

  private

  def sync_related_content_ids(ids)
    transaction do
      event_content_relations.destroy_all
      ids.each_with_index do |related_id, idx|
        event_content_relations.create!(related_event_content_id: related_id, position: idx)
      end
    end
  end

  def persist_pending_related_content_ids
    ids = @pending_related_content_ids
    @pending_related_content_ids = nil
    sync_related_content_ids(ids)
  end
end
