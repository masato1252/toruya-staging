# frozen_string_literal: true

module CustomMessages
  module Customers
    class Template < ActiveInteraction::Base
      ONLINE_SERVICE_PURCHASED = "online_service_purchased"
      ONLINE_SERVICE_MESSAGE_TEMPLATE = "online_service_message_template"
      BOOKING_PAGE_BOOKED= "booking_page_booked"
      BOOKING_PAGE_ONE_DAY_REMINDER = "booking_page_one_day_reminder"

      object :product, class: ApplicationRecord, default: nil
      string :scenario

      validate :validate_product_type

      def execute
        message = CustomMessage.find_by(service: product, scenario: scenario, after_days: nil)
        return message.content if message

        template = case scenario
                   when BOOKING_PAGE_BOOKED
                     I18n.t("customer.notifications.sms.booking")
                   when BOOKING_PAGE_ONE_DAY_REMINDER
                     I18n.t("customer.notifications.sms.reminder")
                   when ONLINE_SERVICE_PURCHASED
                     I18n.t("notifier.online_service.purchased.#{product.solution_type_for_message}.message")
                   end

        if product&.is_a?(BookingPage) && product.shop.phone_number.present?
          template = "#{template}#{I18n.t("customer.notifications.sms.change_from_phone_number")}"
        end

        template
      end

      private

      def validate_product_type
        if product.present? && [OnlineService, BookingPage].exclude?(product.class)
          errors.add(:product, :invalid_type)
        end
      end
    end
  end
end
