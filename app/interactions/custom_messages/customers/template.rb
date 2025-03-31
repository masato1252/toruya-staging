# frozen_string_literal: true

module CustomMessages
  module Customers
    class Template < ActiveInteraction::Base
      ONLINE_SERVICE_PURCHASED = "online_service_purchased"
      ONLINE_SERVICE_MESSAGE_TEMPLATE = "online_service_message_template"
      BOOKING_PAGE_BOOKED = "booking_page_booked" # only for booking_page_booked
      RESERVATION_CONFIRMED = "reservation_confirmed"
      BOOKING_PAGE_ONE_DAY_REMINDER = "booking_page_one_day_reminder"
      RESERVATION_ONE_DAY_REMINDER = 'reservation_one_day_reminder'
      BOOKING_PAGE_CUSTOM_REMINDER = 'booking_page_custom_reminder'
      SHOP_CUSTOM_REMINDER = 'shop_custom_reminder'
      LESSON_WATCHED = 'lesson_watched'
      EPISODE_WATCHED = 'episode_watched'

      SCENARIOS = [ONLINE_SERVICE_PURCHASED, ONLINE_SERVICE_MESSAGE_TEMPLATE, BOOKING_PAGE_BOOKED, RESERVATION_CONFIRMED, BOOKING_PAGE_ONE_DAY_REMINDER, RESERVATION_ONE_DAY_REMINDER, BOOKING_PAGE_CUSTOM_REMINDER, LESSON_WATCHED, EPISODE_WATCHED, SHOP_CUSTOM_REMINDER].freeze

      object :product, class: ApplicationRecord, default: nil
      string :scenario
      boolean :custom_message_only, default: false

      validate :validate_product_type

      def execute
        message = CustomMessage.find_by(service: product, scenario: scenario, after_days: nil)
        return message.content if message
        return if custom_message_only

        template = case scenario
                   when BOOKING_PAGE_BOOKED
                     I18n.t("customer.notifications.sms.booking")
                   when RESERVATION_CONFIRMED
                     I18n.t("customer.notifications.sms.confirmation")
                   when BOOKING_PAGE_ONE_DAY_REMINDER, RESERVATION_ONE_DAY_REMINDER
                     I18n.t("customer.notifications.sms.reminder")
                   when ONLINE_SERVICE_PURCHASED
                     I18n.t("notifier.online_service.purchased.#{product.solution_type_for_message}.message")
                   end

        if template.present? && product&.is_a?(BookingPage) && product.shop.phone_number.present?
          template = "#{template}#{I18n.t("customer.notifications.sms.change_from_phone_number")}"
        end

        template
      end

      private

      def validate_product_type
        if product.present? && [OnlineService, BookingPage, Shop].exclude?(product.class)
          errors.add(:product, :invalid_type)
        end
      end
    end
  end
end
