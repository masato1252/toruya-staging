# frozen_string_literal: true
#
require "utils"

module Templates
  class ReservationVariables < ActiveInteraction::Base
    object :receiver, class: ApplicationRecord # User or Customer
    object :shop
    time :start_time
    time :end_time
    string :meeting_url, default: ''
    string :product_name
    string :booking_page_url, default: ''
    string :booking_info_url, default: ''

    def execute
      booking_time = "#{I18n.l(start_time, format: :long_date_with_wday)} ~ #{I18n.l(end_time, format: :time_only)}"

      {
        customer_name: receiver.name,
        shop_name: shop.display_name,
        shop_phone_number: shop.phone_number,
        booking_time: booking_time,
        meeting_url: Utils.url_with_external_browser(meeting_url),
        product_name: product_name,
        booking_page_url: Utils.url_with_external_browser(booking_page_url),
        booking_info_url: Utils.url_with_external_browser(booking_info_url)
      }
    end
  end
end
