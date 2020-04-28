module Booking
  class FinalizeCode < ActiveInteraction::Base
    object :booking_page
    string :uuid
    object :customer
    object :reservation

    def execute
      if booking_code = booking_page.booking_codes.find_by(uuid: uuid)
        booking_code.update!(customer_id: customer.id, reservation_id: reservation.id)
      end
    end
  end
end
