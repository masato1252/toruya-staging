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
        meeting_url: formatted_meeting_url
      }
    end

    private

    def formatted_meeting_url
      return meeting_url unless meeting_url =~ URI::regexp

      uri = URI.parse(meeting_url)
      query = if uri.query
                CGI.parse(uri.query)
              else
                {}
              end

      query['openExternalBrowser'] = %w(1)
      uri.query = URI.encode_www_form(query)
      uri.to_s
    rescue URI::InvalidURIError
      meeting_url
    end
  end
end
