# == Schema Information
#
# Table name: custom_messages
#
#  id             :bigint           not null, primary key
#  after_days     :integer
#  before_minutes :integer
#  content        :text             not null
#  content_type   :string           default("text")
#  flex_template  :string
#  locale         :string           default("ja")
#  nth_time       :integer          default(1)
#  receiver_ids   :string           default([]), is an Array
#  scenario       :string           not null
#  service_type   :string
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  service_id     :bigint
#
# Indexes
#
#  sequence_message_index  (service_type,service_id,scenario,after_days)
#

require "translator"
require "line_client"

# When service is nil, that's toruya's custom message

class CustomMessage < ApplicationRecord
  TEXT_TYPE = "text"
  FLEX_TYPE = "flex"
  CONTENT_TYPES = [TEXT_TYPE, FLEX_TYPE].freeze

  scope :scenario_of, -> (service, scenario, nth_time = 1) { where(service: service, scenario: scenario, nth_time: nth_time) }
  scope :right_away, -> { where(after_days: nil) }
  scope :sequence, -> { where.not(after_days: nil) }
  validates :service_type, inclusion: { in: %w(OnlineService BookingPage Shop Lesson Episode SurveyActivity Survey) }, allow_nil: true
  validates :content_type, presence: true, inclusion: { in: CONTENT_TYPES }
  validates :scenario, inclusion: { in: CustomMessages::Users::Template::SCENARIOS + CustomMessages::Customers::Template::SCENARIOS }, allow_nil: true
  validates :flex_template, inclusion: { in: ::LineMessages::FlexTemplateContent.singleton_methods(false).map(&:to_s) }, allow_nil: true
  validates :locale, presence: true, inclusion: { in: I18n.available_locales.map(&:to_s) }

  include MalwareScannable

  belongs_to :service, polymorphic: true, optional: true # OnlineService, BookingPage or nil(Toruya user)

  has_one_attached :picture # content picture
  scan_attachment :picture

  def ever_sent_to_user(user)
    SocialUserMessage.where(custom_message_id: id, social_user_id: user.social_user_id).where.not(sent_at: nil).exists?
  end

  def self.user_message_auto_reply(locale)
    scenario_of(nil, CustomMessages::Users::Template::USER_MESSAGE_AUTO_REPLY).where(locale: locale).first
  end

  def self.user_charge_message(locale)
    scenario_of(nil, CustomMessages::Users::Template::USER_CHARGE_MESSAGE).where(locale: locale).first
  end
end
