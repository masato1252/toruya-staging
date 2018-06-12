module Reservations
  class AddReservation < ActiveInteraction::Base
    set_callback :type_check, :before do
      params[:staff_ids] = params[:staff_ids].present? ? params[:staff_ids].split(",").uniq : []
      params[:customer_ids] = params[:customer_ids].present? ? params[:customer_ids].split(",").uniq : []
    end

    object :shop
    object :user
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
      integer :by_staff_id
    end

    def execute
      _reservation = if reservation
                       reservation.attributes = params
                       reservation
                     else
                       # TODO: Future Feature
                       # if current_user.is_super_user?
                         params.merge!(aasm_state: "reserved")
                       # end
                       shop.reservations.new(params)
                     end
      unless _reservation.save
        errors.merge!(_reservation.errors)
      end

      _reservation
    end
  end
end
