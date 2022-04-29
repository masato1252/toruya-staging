# frozen_string_literal: true

module CustomMessages
  class Template < ActiveInteraction::Base
    ONLINE_SERVICE_PURCHASED = "online_service_purchased"
    ONLINE_SERVICE_MESSAGE_TEMPLATE = "online_service_message_template"
    BOOKING_PAGE_BOOKED= "booking_page_booked"
    BOOKING_PAGE_ONE_DAY_REMINDER = "booking_page_one_day_reminder"

    object :product, class: ApplicationRecord
    string :scenario

    validate :validate_product_type

    def execute
      message = CustomMessage.find_by(service: product, scenario: scenario, after_days: nil)
      return message.content if message

      if product.is_a?(BookingPage)
        template = case scenario
                   when BOOKING_PAGE_BOOKED
                     I18n.t("customer.notifications.sms.booking")
                   when BOOKING_PAGE_ONE_DAY_REMINDER
                     I18n.t("customer.notifications.sms.reminder")
                   end

        if product.shop.phone_number.present?
          template = "#{template}#{I18n.t("customer.notifications.sms.change_from_phone_number")}"
        end

        template
      elsif product.is_a?(OnlineService)
        case scenario
        when ONLINE_SERVICE_PURCHASED
          I18n.t("notifier.online_service.purchased.#{product.solution_type_for_message}.message")
        end
      end
    end

    private

    def validate_product_type
      if [OnlineService, BookingPage].exclude?(product.class)
        errors.add(:product, :invalid_type)
      end
    end
  end
end
