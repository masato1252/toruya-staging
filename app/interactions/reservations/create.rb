module Reservations
  class Create < ActiveInteraction::Base
    set_callback :type_check, :before do
      params[:staff_ids] = params[:staff_ids].present? ? params[:staff_ids].split(",").uniq.map(&:to_i) : []
      params[:customer_ids] = params[:customer_ids].present? ? params[:customer_ids].split(",").uniq : []
      params[:by_staff_id] = params[:by_staff_id].to_i
    end

    object :shop
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

      Reservation.transaction do
        # notify non current staff
        other_staff_ids_changes = params[:staff_ids].find_all { |staff_id| staff_id != params[:by_staff_id] }

        if other_staff_ids_changes.present?
          params.merge!(aasm_state: "pending")
        else
          # staffs create a reservation for themselves
          params.merge!(aasm_state: "reserved")
        end

        reservation = shop.reservations.new(params)

        # If the new staff ids includes current user staff, the staff accepted the reservation automatically
        if reservation_staff = reservation.reservation_staffs.find { |reservation_staff| reservation_staff.staff_id == params[:by_staff_id] }
          reservation_staff.state = ReservationStaff.states[:accepted]
        end

        unless reservation.save
          errors.merge!(reservation.errors)
          raise ActiveRecord::Rollback
        end

        reservation
      end
    end
  end
end
