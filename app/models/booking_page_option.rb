# frozen_string_literal: true

# == Schema Information
#
# Table name: booking_page_options
#
#  id                :bigint           not null, primary key
#  booking_option_id :bigint           not null
#  booking_page_id   :bigint           not null
#
# Indexes
#
#  index_booking_page_options_on_booking_option_id  (booking_option_id)
#  index_booking_page_options_on_booking_page_id    (booking_page_id)
#

class BookingPageOption < ApplicationRecord
  belongs_to :booking_page
  belongs_to :booking_option
end
