module Reservations
  class AddReservation < ActiveInteraction::Base
    set_callback :type_check, :before do
      params[:staff_ids] = params[:staff_ids].present? ? params[:staff_ids].split(",") : []
      params[:customer_ids] = params[:customer_ids].present? ? params[:customer_ids].split(",") : []
    end

    object :shop, class: Shop
    object :reservation, class: Reservation, default: nil
    hash :params do
      string :start_time_date_part
      string :start_time_time_part
      string :end_time_time_part
      integer :menu_id
      array :staff_ids
      array :customer_ids
      string :memo, default: nil
    end

    def execute
      _reservation = if reservation
                       reservation.attributes = params
                       reservation
                     else
                       shop.reservations.new(params)
                     end
      unless _reservation.save
        errors.merge!(_reservation.errors)
      end
      reservation
    end
  end
end
