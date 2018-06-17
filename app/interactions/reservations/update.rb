module Reservations
  class Update < ActiveInteraction::Base
    set_callback :type_check, :before do
      params[:staff_ids] = params[:staff_ids].present? ? params[:staff_ids].split(",").uniq.map(&:to_i) : []
      params[:customer_ids] = params[:customer_ids].present? ? params[:customer_ids].split(",").uniq : []
      params[:by_staff_id] = params[:by_staff_id].to_i
    end

    object :shop
    object :reservation
    hash :params do
      string :start_time_date_part
      string :start_time_time_part
      string :end_time_time_part
      integer :menu_id
      array :staff_ids
      array :customer_ids
      string :memo, default: nil
      boolean :with_warnings
      integer :by_staff_id
    end

    def execute
      other_staff_ids_changes = []

      reservation.transaction do
        staff_ids = params.delete(:staff_ids)
        staff_ids_changes = staff_ids - reservation.staff_ids
        other_staff_ids_changes = staff_ids_changes.find_all { |staff_id| staff_id != params[:by_staff_id] }

        # Build new correct assoications
        reservation.staff_ids = staff_ids

        # If the new staff ids includes current user staff, the staff accepted the reservation automatically
        if reservation_staff = reservation.reservation_staffs.find_by(staff_id: params[:by_staff_id])
          reservation_staff.update(state: ReservationStaff.states[:accepted])
        end

        # If all staffs accepted the reservation, the reservation be accepted automatically
        reservation.aasm_state = "reserved" if reservation.accepted_by_all_staffs?

        reservation.attributes = params

        if reservation.save
          if reservation.pending?
            shop.user.staffs.where(id: other_staff_ids_changes).each do |staff|
              ReservationMailer.pending(reservation, staff).deliver_later
            end
          end
        else
          errors.merge!(reservation.errors)
          raise ActiveRecord::Rollback
        end

        reservation
      end
    end
  end
end
