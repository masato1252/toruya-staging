# frozen_string_literal: true

module CustomMessages
  module Users
    class Template < ActiveInteraction::Base
      USER_MESSAGE_AUTO_REPLY = "user_message_auto_reply"
      USER_SIGN_UP = "user_sign_up"
      LINE_SETTINGS_VERIFIED = "line_settings_verified"
      FIRST_BOOKING_PAGE_CREATED = "first_booking_page_created"
      SECOND_BOOKING_PAGE_CREATED = "second_booking_page_created"
      ELEVENTH_BOOKING_PAGE_CREATED = "eleventh_booking_page_created"
      FIRST_CUSTOMER_DATA_MANUALLY_CREATED = "first_customer_data_manually_created"
      BOOKING_PAGE_NOT_ENOUGH_PAGE_VIEW = "booking_page_not_enough_page_view"
      BOOKING_PAGE_NOT_ENOUGH_BOOKING = "booking_page_not_enough_booking"
      NO_NEW_CUSTOMER = "no_new_customer"
      NO_LINE_SETTINGS = "no_line_settings"

      SCENARIOS = [
        USER_MESSAGE_AUTO_REPLY,
        USER_SIGN_UP,
        LINE_SETTINGS_VERIFIED,
        FIRST_BOOKING_PAGE_CREATED,
        SECOND_BOOKING_PAGE_CREATED,
        ELEVENTH_BOOKING_PAGE_CREATED,
        FIRST_CUSTOMER_DATA_MANUALLY_CREATED,
        BOOKING_PAGE_NOT_ENOUGH_PAGE_VIEW,
        BOOKING_PAGE_NOT_ENOUGH_BOOKING,
        NO_NEW_CUSTOMER,
        NO_LINE_SETTINGS
      ].freeze

      string :scenario
      string :locale

      validate :validate_product_type

      def execute
        message = CustomMessage.find_by(scenario: scenario, after_days: nil, locale: locale)
        return message.content if message

        case scenario
        when *SCENARIOS
          # no default template
        end
      end
    end
  end
end
