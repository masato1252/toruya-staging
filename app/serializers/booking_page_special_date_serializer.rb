# frozen_string_literal: true

class BookingPageSpecialDateSerializer
  include JSONAPI::Serializer

  attribute :full_start_time, &:start_at
  attribute :full_end_time, &:end_at
  attributes :id, :booking_page_id

  attribute :type do |_|
    :booking_page_holder_schedule
  end

  attribute :start_date do |schedule|
    I18n.l(schedule.start_at, format: :date)
  end

  attribute :start_time do |schedule|
    schedule.start_at.to_fs(:time)
  end

  attribute :end_time do |schedule|
    schedule.end_at.to_fs(:time)
  end

  attribute :time do |schedule|
    schedule.start_at
  end

  attribute :title do |schedule|
    schedule.booking_page.name
  end

  attribute :reason do |schedule|
    schedule.booking_page.name
  end

  attribute :shop_name do |schedule|
    schedule.booking_page.shop.display_name
  end
end
