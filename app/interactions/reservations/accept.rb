module Reservations
  class Accept < ActiveInteraction::Base
    object :current_staff, class: Staff
    object :reservation

    def execute
      unless reservation.may_accept?
        errors.add(:reservation, :not_acceptable)
        return
      end

      reservation.transaction do
        reservation.by_staff = current_staff

        if reservation.for_staff(current_staff)
          reservation.for_staff(current_staff).accepted!

          if reservation.accepted_by_all_staffs?
            reservation.accept
          else
            # if current_staff.can?(:manage, Reservation)
              # reservation.accept
              # reservation.reservation_staffs.where(state: Reservation.states[:pending]).update_all(state: Reservation.states[:accepted])
            # end
          end
        # elsif current_staff.can?(:manage, Reservation)
          # reservation.accept
          # reservation.reservation_staffs.where(state: Reservation.states[:pending]).update_all(state: Reservation.states[:accepted])
        end

        reservation
      end
    end
  end
end
