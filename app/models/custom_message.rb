# == Schema Information
#
# Table name: custom_messages
#
#  id           :bigint(8)        not null, primary key
#  scenario     :string           not null
#  service_type :string           not null
#  service_id   :bigint(8)        not null
#  content      :text             not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
# Indexes
#
#  index_custom_messages_on_service_type_and_service_id  (service_type,service_id)
#

# position
# after_last_message_days
# receiver_ids
require "translator"
require "line_client"

class CustomMessage < ApplicationRecord
  ONLINE_SERVICE_PURCHASED = "online_service_purchased"
  BOOKING_PAGE_BOOKED= "booking_page_booked"

  belongs_to :service, polymorphic: true # OnlineService

  def demo_message_for_owner
    user = service.user

    custom_message_content =
      case service
      when BookingPage
        custom_message_content = Translator.perform(content, {
          customer_name: user.display_last_name,
          shop_name: service.shop.display_name,
          shop_phone_number: service.shop.phone_number,
          booking_time: "#{I18n.l(Time.current, format: :long_date_with_wday)} ~ #{I18n.l(Time.current.advance(hours: 1), format: :time_only)}"
        })
      when OnlineService
        Translator.perform(content, { customer_name: user.display_last_name, service_title: service.name})
      end

    LineClient.send(user.social_user, custom_message_content)
  end

  def self.template_of(product, scenario, position)
    message = CustomMessage.find_by(service: product, scenario: scenario, position: position)

    return message.content if message

    case scenario
    when ONLINE_SERVICE_PURCHASED
      I18n.t("notifier.online_service.purchased.#{product.solution_type}.message")
    when BOOKING_PAGE_BOOKED
      I18n.t("customer.notifications.sms.booking")
    end
  end
end
