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
        reservation.by_staff = current_staff
        reservation.reservation_staffs.update_all(state: ReservationStaff.states[:pending])
        reservation.pend!

        other_reservation_staffs = reservation.reservation_staffs.where.not(staff_id: current_staff.id)

        if other_reservation_staffs.exists?
          other_reservation_staffs.each do |reservation_staff|
            ReservationMailer.pending(reservation_staff.reservation, reservation_staff.staff).deliver_later
          end
        end

        reservation
      end
    end
  end
end
