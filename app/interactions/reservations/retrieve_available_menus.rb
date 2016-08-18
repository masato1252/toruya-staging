module Reservations
  class RetrieveAvailableMenus < ActiveInteraction::Base
    set_callback :type_check, :before do
      if params && params[:start_time_date_part] && params[:start_time_time_part] && params[:end_time_time_part]
        start_time = Time.zone.parse("#{params[:start_time_date_part]}-#{params[:start_time_time_part]}")
        end_time = Time.zone.parse("#{params[:start_time_date_part]}-#{params[:end_time_time_part]}")

        self.reservation_time ||= start_time..end_time
      end

      if reservation
        self.reservation_time ||= reservation.start_time..reservation.end_time
      end
    end

    object :shop, class: Shop
    object :reservation_time, class: Range, default: nil
    object :reservation, class: Reservation, default: nil
    hash :params, default: nil do
      string :start_time_date_part, default: nil
      string :start_time_time_part, default: nil
      string :end_time_time_part, default: nil
      integer :menu_id, default: nil
    end

    def execute
      menus = shop.available_reservation_menus(reservation_time, reservation.try(:id))

      staffs = if menus.present?
                 selected_menu = reservation.try(:menu) || shop.menus.find_by(id: params["menu_id"]) || menus.first
                 shop.available_staffs(selected_menu, reservation_time, reservation.try(:id))
               else
                 []
               end

      { menus: menus, staffs: staffs, selected_menu: selected_menu }
    end
  end
end
