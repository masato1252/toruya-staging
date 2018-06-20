module Reservations
  class Accept < ActiveInteraction::Base
    object :current_staff, class: Staff
    object :reservation

    validate :validate_reservation
    validate :validate_staff

    def execute
      reservation.transaction do
        reservation_for_staff.accepted!
        reservation.accept if reservation.accepted_by_all_staffs?
        reservation.save
        reservation
      end
    end

    private

    def validate_reservation
      errors.add(:reservation, :not_acceptable) unless reservation.may_accept?
    end

    def validate_staff
      errors.add(:current_staff, :who_r_u) unless reservation_for_staff
    end

    def reservation_for_staff
      @reservation_for_staff ||= reservation.for_staff(current_staff)
    end
  end
end
