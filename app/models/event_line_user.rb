# frozen_string_literal: true

class EventLineUser < ApplicationRecord
  belongs_to :toruya_user, class_name: "User", optional: true
  belongs_to :toruya_social_user, class_name: "SocialUser", optional: true

  has_many :event_participants, dependent: :destroy
  has_many :events, through: :event_participants
  has_many :event_content_usages, dependent: :destroy
  has_many :event_upsell_consultations, dependent: :destroy
  has_many :event_monitor_applications, dependent: :destroy
  has_many :event_activity_logs, dependent: :destroy

  validates :line_user_id, presence: true, uniqueness: true

  def toruya_registered?
    toruya_user_id.present?
  end

  def check_toruya_user!
    social_user = SocialUser.where(social_service_user_id: line_user_id)
                            .where.not(user_id: nil).first
    if social_user
      self.toruya_user_id = social_user.user_id
      self.toruya_social_user_id = social_user.id
    end
    self.toruya_user_checked_at = Time.current
    save! if persisted?
  end

  def profile_complete?
    first_name.present? && last_name.present?
  end

  def name
    "#{last_name} #{first_name}".strip
  end
end
