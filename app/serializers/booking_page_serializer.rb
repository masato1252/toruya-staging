# frozen_string_literal: true

class BookingPageSerializer
  include JSONAPI::Serializer
  attribute :id, :name, :shop_id, :product_name

  attribute :url do |booking_page|
    Rails.application.routes.url_helpers.booking_page_url(booking_page.slug)
  end

  attribute :price_number do |booking_page|
    booking_page.product_price&.fractional
  end

  attribute :price do |booking_page|
    if booking_page.user.currency == "JPY"
      booking_page.product_price&.format(:ja_default_format)
    else
      booking_page.product_price&.format
    end
  end

  attribute :start_time do |booking_page|
    booking_page.start_time_text
  end

  attribute :end_time do |booking_page|
    booking_page.end_time_text
  end

  attribute :is_started do |booking_page|
    booking_page.started?
  end

  attribute :is_ended do |booking_page|
    booking_page.ended?
  end
end
