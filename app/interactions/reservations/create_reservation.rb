module Reservations
  class CreateReservation < ActiveInteraction::Base
    set_callback :type_check, :before do
      params[:staff_ids] = params[:staff_ids].present? ? params[:staff_ids].split(",") : []
      params[:customer_ids] = params[:customer_ids].present? ? params[:customer_ids].split(",") : []
    end

    object :shop, class: Shop
    hash :params do
      string :start_time_date_part
      string :start_time_time_part
      string :end_time_time_part
      integer :menu_id
      array :staff_ids
      array :customer_ids
    end

    def execute
      reservation = shop.reservations.new(params.except(:staff_ids, :customer_ids))
      reservation.staff_ids = params[:staff_ids]
      reservation.customer_ids = params[:customer_ids]
      reservation.save
      reservation
    end
  end
end
