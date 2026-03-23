# frozen_string_literal: true

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

  BUSINESS_AGE_LABELS = {
    0 => "1年未満",
    1 => "1〜3年",
    2 => "3年以上"
  }.freeze

  belongs_to :event
  belongs_to :social_customer
  belongs_to :user, optional: true

  enum business_age: { under_one_year: 0, one_to_three_years: 1, over_three_years: 2 }, _suffix: true

  validates :registered_at, presence: true
  validates :social_customer_id, uniqueness: { scope: :event_id }

  def self.concern_category_for(label)
    CONCERN_MAPPING[label]&.dig(:category)
  end

  def self.recommended_roles_for(label)
    CONCERN_MAPPING[label]&.dig(:roles) || []
  end
end
