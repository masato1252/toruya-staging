module Reservations
  class Create < ActiveInteraction::Base
    set_callback :type_check, :before do
      params[:staff_ids] = params[:staff_ids].present? ? params[:staff_ids].split(",").uniq : []
      params[:customer_ids] = params[:customer_ids].present? ? params[:customer_ids].split(",").uniq : []
    end

    object :shop
    object :reservation, default: nil
    hash :params do
      string :start_time_date_part
      string :start_time_time_part
      string :end_time_time_part
      integer :menu_id
      array :staff_ids
      array :customer_ids
      string :memo, default: nil
      boolean :with_warnings
      string :by_staff_id
    end

    def execute
      other_staff_ids_changes = []

      _reservation =
        if reservation
          other_staff_ids_changes = (params[:staff_ids] - reservation.staff_ids).find_all { |staff_id| staff_id != params[:by_staff_id] }

          reservation.attributes = params
          reservation
        else
          # notify non current staff
          other_staff_ids_changes = params[:staff_ids].find_all { |staff_id| staff_id != params[:by_staff_id] }

          if other_staff_ids_changes.present?
            params.merge!(aasm_state: "pending")
          else
            params.merge!(aasm_state: "reserved")
          end

          shop.reservations.new(params)
        end

      if _reservation.save
        if _reservation.pending?
          shop.user.staffs.where(id: other_staff_ids_changes).each do |staff|
            ReservationMailer.pending(_reservation, staff).deliver_later
          end
        end
      else
        errors.merge!(_reservation.errors)
      end

      _reservation
    end
  end
end
