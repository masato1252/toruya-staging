module Reservations
  class RetrieveAvailableMenus < ActiveInteraction::Base
    set_callback :type_check, :before do
      params[:staff_ids] = if params[:staff_ids].present?
                             params[:staff_ids].split(",")
                           elsif reservation
                             reservation.staff_ids
                           else
                             []
                           end

      params[:customer_ids] = if params[:customer_ids].present?
                             params[:customer_ids].split(",")
                           elsif reservation
                             reservation.customer_ids
                           else
                             []
                           end
      params[:menu_id] = params[:menu_id].presence || reservation.try(:menu_id)
      params[:start_time_date_part] = params[:start_time_date_part].presence || reservation.try(:start_time_date)
      params[:start_time_time_part] = params[:start_time_time_part].presence || reservation.try(:start_time_time)
      params[:end_time_time_part] = params[:end_time_time_part].presence || reservation.try(:end_time_time)
      start_time = Time.zone.parse("#{params[:start_time_date_part]}-#{params[:start_time_time_part]}")
      end_time = Time.zone.parse("#{params[:start_time_date_part]}-#{params[:end_time_time_part]}")
      self.reservation_time ||= start_time..end_time
    end

    object :shop, class: Shop
    object :reservation_time, class: Range, default: nil
    object :reservation, class: Reservation, default: nil
    hash :params do
      string :start_time_date_part, default: nil
      string :start_time_time_part, default: nil
      string :end_time_time_part, default: nil
      integer :menu_id, default: nil
      array :staff_ids, default: nil
      array :customer_ids, default: nil
    end

    def execute
      reservation.attributes = params.except(:reservation_id, :controller, :action, :from_reservation) if reservation
      menu_options = shop.available_reservation_menus(reservation_time, params[:customer_ids].size, reservation.try(:id))
      menu_option_ids = menu_options.map(&:id)

      staff_options = if menu_options.present?
                        selected_menu = if menu_option_ids.include?(params[:menu_id])
                                          shop.menus.find_by(id: params["menu_id"])
                                        elsif menu_option_ids.include?(reservation.try(:menu).try(:id))
                                          reservation.try(:menu)
                                        else
                                          menu_options.first
                                        end

                        shop.available_staffs(selected_menu, reservation_time, reservation.try(:id))
                      else
                        []
                      end

      { menu_options: menu_options,
        staff_options: staff_options,
        selected_menu: selected_menu,
        reservation: reservation }
    end
  end
end
