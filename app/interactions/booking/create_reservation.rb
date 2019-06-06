module Booking
  class CreateReservation < ActiveInteraction::Base
    object :booking_page
    integer :booking_option_id
    time :booking_at
    string :customer_last_name
    string :customer_first_name
    string :customer_phone_number
    hash :customer_info, strip: false

    def execute
    end
  end
end
