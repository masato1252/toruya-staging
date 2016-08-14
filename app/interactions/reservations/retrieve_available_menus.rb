module Reservations
  class RetrieveAvailableMenus < ActiveInteraction::Base
    set_callback :type_check, :before do
      start_time = Time.zone.parse("#{params[:start_time_date_part]}-#{params[:start_time_time_part]}")
      end_time = Time.zone.parse("#{params[:start_time_date_part]}-#{params[:end_time_time_part]}")

      self.reservation_time = start_time..end_time
    end

    object :shop, class: Shop
    object :reservation_time, class: Range
    hash :params do
      string :start_time_date_part
      string :start_time_time_part
      string :end_time_time_part
    end

    def execute
      menus = shop.available_reservation_menus(reservation_time)

      staffs = if menus.present?
                 selected_menu = menus.first
                 shop.available_staffs(selected_menu, reservation_time)
               end

      { menus: menus, staffs: staffs, selected_menu: selected_menu }
    end
  end
end
