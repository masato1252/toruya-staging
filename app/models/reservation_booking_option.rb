# frozen_string_literal: true

# == Schema Information
#
# Table name: reservation_booking_options
#
#  id                :bigint           not null, primary key
#  booking_option_id :bigint
#  reservation_id    :bigint
#
# Indexes
#
#  index_reservation_booking_options_on_booking_option_id  (booking_option_id)
#  index_reservation_booking_options_on_reservation_id     (reservation_id)
#

class ReservationBookingOption < ApplicationRecord
  belongs_to :booking_option
end
