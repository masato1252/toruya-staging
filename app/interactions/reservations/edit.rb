module Reservations
  class Edit < ActiveInteraction::Base
    object :reservation
    hash :params, default: {} do
      string :start_time_date_part, default: nil
      string :start_time_time_part, default: nil
      string :end_time_time_part, default: nil
      integer :menu_id, default: nil
      string :customer_ids, default: nil
      string :staff_ids, default: nil
    end

    def execute
      reservation.start_time_date_part = params[:start_time_date_part].presence || reservation.try(:start_time_date)
      reservation.start_time_time_part = params[:start_time_time_part].presence || reservation.try(:start_time_time)
      reservation.end_time_time_part = params[:end_time_time_part].presence || reservation.try(:end_time_time)
      reservation.customer_ids = if params[:customer_ids].present?
                                   params[:customer_ids].split(",").map{ |c| c if c.present? }.compact.uniq
                                 elsif reservation
                                   reservation.customer_ids
                                 else
                                   []
                                 end
      reservation.staff_ids = if params[:staff_ids].present?
                                params[:staff_ids].split(",").map{ |c| c if c.present? }.compact.uniq
                              elsif reservation
                                reservation.staff_ids
                              else
                                []
                              end
      reservation
    end
  end
end
