# frozen_string_literal: true

# == Schema Information
#
# Table name: event_participants
#
#  id                 :bigint           not null, primary key
#  business_age       :integer
#  business_types     :jsonb            not null
#  concern_categories :jsonb            not null
#  concern_labels     :jsonb            not null
#  concern_other      :string
#  registered_at      :datetime         not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  event_id           :bigint           not null
#  event_line_user_id :bigint
#  social_customer_id :bigint
#  user_id            :bigint
#
# Indexes
#
#  index_event_participants_on_event_id                         (event_id)
#  index_event_participants_on_event_id_and_social_customer_id  (event_id,social_customer_id) UNIQUE
#  index_event_participants_on_event_line_user_id               (event_line_user_id)
#  index_event_participants_on_social_customer_id               (social_customer_id)
#  index_event_participants_on_user_id                          (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (event_id => events.id)
#  fk_rails_...  (event_line_user_id => event_line_users.id)
#  fk_rails_...  (social_customer_id => social_customers.id)
#  fk_rails_...  (user_id => users.id)
#
class EventParticipant < ApplicationRecord
  CONCERN_MAPPING = {
    "新規のお客様がなかなか増えない" => { category: "acquisition", roles: ["LINE集客コンサル", "SNS集客コンサル"] },
    "SNSやホームページを頑張っているのに予約に繋がらない" => { category: "acquisition", roles: ["WEBデベロッパー", "SNS集客コンサル"] },
    "紹介だけに頼っていて自分で集客する方法が分からない" => { category: "acquisition", roles: ["LINE集客コンサル", "セミナー講師"] },
    "LINEを導入したが使いこなせていない" => { category: "line_tool", roles: ["LINE集客コンサル"] },
    "LINEはメッセージ送受信にしか使えていない" => { category: "line_tool", roles: ["LINE集客コンサル"] },
    "ホームページやSNSの見た目・デザインをもっとよくしたい" => { category: "line_tool", roles: ["デザイナー"] },
    "発信したいことはあるのにうまく言葉にできない" => { category: "content", roles: ["ライター"] },
    "ブログや文章を書くのが苦手で続かない" => { category: "content", roles: ["ライター"] },
    "集客のための文章や資料をどう作ればいいか分からない" => { category: "content", roles: ["ライター", "デザイナー"] },
    "予約は入っているのに売上が安定しない" => { category: "management", roles: ["経営コンサル", "セミナー講師"] },
    "単価を上げたいがどうすれば良いか分からない" => { category: "management", roles: ["経営コンサル"] },
    "確定申告や税金・お金の管理が不安" => { category: "management", roles: ["税理士"] },
    "売上はあっても手元にお金が残らない" => { category: "management", roles: ["税理士", "経営コンサル"] },
    "集客・事務作業に時間がかかりすぎて施術に集中できない" => { category: "efficiency", roles: ["LINE集客コンサル", "WEBデベロッパー"] },
    "リピーターが少なく毎月集客し直しになっている" => { category: "efficiency", roles: ["LINE集客コンサル", "SNS集客コンサル"] },
    "予約管理や顧客対応の仕組みをもっと整えたい" => { category: "efficiency", roles: ["WEBデベロッパー", "LINE集客コンサル"] },
    "その他（自由記述）" => { category: "other", roles: [] }
  }.freeze

  BUSINESS_TYPES = %w[
    セラピスト
    整体師
    ネイリスト
    アイリスト
    Yoga講師
    ピラティス講師
    美容師
    スクール講師
    その他
  ].freeze

  EXHIBITOR_ROLES = [
    "LINE集客コンサル",
    "SNS集客コンサル",
    "WEBデベロッパー",
    "セミナー講師",
    "デザイナー",
    "ライター",
    "経営コンサル",
    "税理士"
  ].freeze

  BUSINESS_AGE_LABELS = {
    0 => "1年未満",
    1 => "1〜3年",
    2 => "3年以上"
  }.freeze

  belongs_to :event
  belongs_to :event_line_user

  enum business_age: { under_one_year: 0, one_to_three_years: 1, over_three_years: 2 }, _suffix: true

  validates :registered_at, presence: true
  validates :event_line_user_id, uniqueness: { scope: :event_id }
  validate :concern_labels_max_six

  def self.concern_category_for(label)
    CONCERN_MAPPING[label]&.dig(:category)
  end

  def self.recommended_roles_for(label)
    CONCERN_MAPPING[label]&.dig(:roles) || []
  end

  def recommended_roles
    (concern_labels || []).flat_map { |label| CONCERN_MAPPING[label]&.dig(:roles) || [] }.uniq
  end

  private

  def concern_labels_max_six
    return if concern_labels.blank?

    errors.add(:concern_labels, "は最大6件までです") if concern_labels.size > 6
  end
end
