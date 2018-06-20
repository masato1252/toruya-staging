module Reservations
  class Pend < ActiveInteraction::Base
    object :current_staff, class: Staff
    object :reservation

    def execute
      unless reservation.may_pend?
        errors.add(:reservation, :not_acceptable)
        return
      end

      reservation.transaction do
        reservation.reservation_staffs.update_all(state: ReservationStaff.states[:pending])
        reservation.pend!
        reservation
      end
    end
  end
end
