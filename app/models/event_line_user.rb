# frozen_string_literal: true

# == Schema Information
#
# Table name: event_line_users
#
#  id                     :bigint           not null, primary key
#  business_age           :integer
#  business_types         :jsonb            not null
#  display_name           :string
#  email                  :string
#  first_name             :string
#  last_name              :string
#  phone_number           :string
#  picture_url            :string
#  toruya_user_checked_at :datetime
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  line_user_id           :string           not null
#  toruya_social_user_id  :bigint
#  toruya_user_id         :bigint
#
# Indexes
#
#  index_event_line_users_on_email                  (email)
#  index_event_line_users_on_line_user_id           (line_user_id) UNIQUE
#  index_event_line_users_on_phone_number           (phone_number)
#  index_event_line_users_on_toruya_social_user_id  (toruya_social_user_id)
#  index_event_line_users_on_toruya_user_id         (toruya_user_id)
#
class EventLineUser < ApplicationRecord
  belongs_to :toruya_user, class_name: "User", optional: true
  belongs_to :toruya_social_user, class_name: "SocialUser", optional: true

  has_many :event_participants, dependent: :destroy
  has_many :events, through: :event_participants
  has_many :event_content_usages, dependent: :destroy
  has_many :event_upsell_consultations, dependent: :destroy
  has_many :event_monitor_applications, dependent: :destroy
  has_many :event_activity_logs, dependent: :destroy
  has_many :event_stamp_entries, dependent: :destroy
  has_many :event_line_message_deliveries, dependent: :destroy

  validates :line_user_id, presence: true, uniqueness: true

  def toruya_registered?
    toruya_user_ids.any?
  end

  def toruya_user_ids
    @toruya_user_ids ||= begin
      ids = []
      ids << toruya_user_id if toruya_user_id.present?
      ids.concat(
        SocialUser.where(social_service_user_id: line_user_id)
                  .where.not(user_id: nil)
                  .pluck(:user_id)
      )
      ids.compact.uniq
    end
  end

  def resolved_toruya_user_id
    toruya_user_ids.first
  end

  def check_toruya_user!
    social_user = SocialUser.where(social_service_user_id: line_user_id)
                            .where.not(user_id: nil).first
    if social_user
      self.toruya_user_id = social_user.user_id
      self.toruya_social_user_id = social_user.id
    end
    @toruya_user_ids = nil
    self.toruya_user_checked_at = Time.current
    save! if persisted?
  end

  def profile_complete?
    basic_profile_complete?
  end

  # イベント参加登録で求める最低限の連絡先（解析・リード用）。
  def basic_profile_complete?
    first_name.present? && last_name.present? && email.present? && phone_number.present?
  end

  def name
    "#{last_name} #{first_name}".strip
  end

  # 管理画面の参加者一覧用。プロフィール未完了時は「-」。
  def admin_display_name
    return "-" unless basic_profile_complete?

    name.presence || "-"
  end

  # 管理画面表示用。日本の電話番号は 0 始まりの国内形式に正規化する。
  def formatted_phone_number
    raw = phone_number.presence
    return nil if raw.blank?

    parsed = Phonelib.parse(raw)
    parsed = Phonelib.parse(raw, "JP") unless parsed.valid?

    if parsed.valid? && parsed.countries.include?("JP")
      parsed.national(false)
    elsif parsed.valid?
      parsed.international(false).presence || raw
    else
      normalize_japanese_phone_digits(raw)
    end
  end

  private

  def normalize_japanese_phone_digits(raw)
    digits = raw.gsub(/\D/, "")
    return digits if digits.match?(/\A0\d{9,10}\z/)
    return "0#{digits[2..]}" if digits.match?(/\A81\d{9,10}\z/)

    digits.presence || raw
  end
end
