# == Schema Information
#
# Table name: booking_page_options
#
#  id                :bigint(8)        not null, primary key
#  booking_page_id   :bigint(8)        not null
#  booking_option_id :bigint(8)        not null
#
# Indexes
#
#  index_booking_page_options_on_booking_option_id  (booking_option_id)
#  index_booking_page_options_on_booking_page_id    (booking_page_id)
#

class BookingPageOption < ApplicationRecord
  belongs_to :page, class_name: "BookingPage", foreign_key: :booking_page_id
  belongs_to :option, class_name: "BookingOption", foreign_key: :booking_option_id
end
