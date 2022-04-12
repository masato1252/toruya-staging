# == Schema Information
#
# Table name: custom_messages
#
#  id           :bigint           not null, primary key
#  after_days   :integer
#  content      :text             not null
#  receiver_ids :string           default([]), is an Array
#  scenario     :string           not null
#  service_type :string           not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  service_id   :bigint           not null
#
# Indexes
#
#  sequence_message_index  (service_type,service_id,scenario,after_days)
#

require "translator"
require "line_client"

class CustomMessage < ApplicationRecord
  ONLINE_SERVICE_PURCHASED = "online_service_purchased"
  ONLINE_SERVICE_MESSAGE_TEMPLATE = "online_service_message_template"
  BOOKING_PAGE_BOOKED= "booking_page_booked"
  BOOKING_PAGE_ONE_DAY_REMINDER = "booking_page_one_day_reminder"

  scope :scenario_of, -> (service, scenario) { where(service: service, scenario: scenario) }
  scope :right_away, -> { where(after_days: nil) }
  scope :sequence, -> { where.not(after_days: nil) }
  validates :service_type, inclusion: { in: %w(OnlineService BookingPage) }

  belongs_to :service, polymorphic: true # OnlineService, BookingPage

  has_one_attached :picture # content picture

  def demo_message_content
    Translator.perform(content, service.message_template_variables(service.user))
  end

  def demo_message_for_owner
    LineClient.send(service.user.social_user, demo_message_content)
  end

  def self.template_of(product, scenario)
    message = CustomMessage.find_by(service: product, scenario: scenario, after_days: nil) if product

    return message.content if message

    case scenario
    when ONLINE_SERVICE_PURCHASED
      I18n.t("notifier.online_service.purchased.#{product.solution_type_for_message}.message")
    when BOOKING_PAGE_BOOKED
      I18n.t("customer.notifications.sms.booking")
    when BOOKING_PAGE_ONE_DAY_REMINDER
      I18n.t("customer.notifications.sms.reminder")
    end
  end
end
