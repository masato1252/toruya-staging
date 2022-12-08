# frozen_string_literal: true

module Reservations
  class Pend < ActiveInteraction::Base
    object :reservation

    def execute
      reservation.transaction do
        reservation.reservation_staffs.update_all(state: ReservationStaff.states[:pending])
        reservation.pend!
        reservation
      end
    end
  end
end
