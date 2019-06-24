# == Schema Information
#
# Table name: reservation_booking_options
#
#  id                :bigint(8)        not null, primary key
#  reservation_id    :bigint(8)
#  booking_option_id :bigint(8)
#
# Indexes
#
#  index_reservation_booking_options_on_booking_option_id  (booking_option_id)
#  index_reservation_booking_options_on_reservation_id     (reservation_id)
#

class ReservationBookingOption < ApplicationRecord
  belongs_to :booking_option
end
