# frozen_string_literal: true

# == Schema Information
#
# Table name: booking_page_special_dates
#
#  id              :bigint(8)        not null, primary key
#  booking_page_id :bigint(8)        not null
#  start_at        :datetime         not null
#  end_at          :datetime         not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
# Indexes
#
#  index_booking_page_special_dates_on_booking_page_id  (booking_page_id)
#

class BookingPageSpecialDate < ApplicationRecord
  include DateTimeAccessor
  date_time_accessor :start_at, :end_at

  scope :future, -> { where("booking_page_special_dates.start_at > ?", Time.current) }

  belongs_to :booking_page
end
