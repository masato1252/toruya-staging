# frozen_string_literal: true

class BookingPageCacheJob < ApplicationJob
  queue_as :low_priority

  def perform(booking_page)
    (Date.today..Date.today.next_month.next_month).each do |date|
      ::Booking::Cache.run(booking_page: booking_page, date: date)
    end
  end
end
