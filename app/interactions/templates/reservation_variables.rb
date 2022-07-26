# frozen_string_literal: true
#
module Templates
  class ReservationVariables < ActiveInteraction::Base
    object :receiver, class: ApplicationRecord # User or Customer
    object :shop
    time :start_time
    time :end_time
    string :meeting_url, default: ''

    def execute
      booking_time = "#{I18n.l(start_time, format: :long_date_with_wday)} ~ #{I18n.l(end_time, format: :time_only)}"

      {
        customer_name: receiver.display_last_name,
        shop_name: shop.display_name,
        shop_phone_number: shop.phone_number,
        booking_time: booking_time,
        meeting_url: meeting_url
      }
    end
  end
end
