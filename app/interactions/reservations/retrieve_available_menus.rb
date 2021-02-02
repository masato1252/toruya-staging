# frozen_string_literal: true

module Reservations
  class RetrieveAvailableMenus < ActiveInteraction::Base
    set_callback :type_check, :before do
      params[:customer_ids] = if params[:customer_ids].present?
                                params[:customer_ids].split(",").map{ |c| c if c.present? }.compact.uniq
                              elsif reservation
                                reservation.customer_ids
                              else
                                []
                              end
      params[:staff_ids] = if params[:staff_ids].present?
                                params[:staff_ids].split(",").map{ |c| c if c.present? }.compact.uniq
                              elsif reservation
                                reservation.staff_ids
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

    object :shop
    object :reservation_time, class: Range
    object :reservation, default: nil
    # XXX: ActiveInteraction BUG, it need to pass default value here, otherwise it would not strip other keys.
    hash :params, default: {} do
      string :start_time_date_part, default: nil
      string :start_time_time_part, default: nil
      string :end_time_time_part, default: nil
      integer :menu_id, default: nil
      array :customer_ids, default: nil
      array :staff_ids, default: nil
    end

    def execute
      reservation.attributes = params.slice(:start_time_date_part, :start_time_time_part, :end_time_time_part, :menu_id, :customer_ids, :staff_ids) if reservation
      menu_options = Reservable::Menus.run!(shop: shop,
                                            business_time_range: reservation_time,
                                            number_of_customer: params[:customer_ids].size,
                                            reservation_id: reservation.try(:id))

      _category_with_menus = compose(Menus::CategoryGroup, menu_options: menu_options)

      menu_options = _category_with_menus[:menu_options]
      menu_ids = menu_options.map(&:id)

      staff_options = if menu_options.present?
                        selected_menu_option = if menu_ids.include?(params[:menu_id].to_i)
                                                 menu_options.find { |menu_option| menu_option.id == params[:menu_id].to_i }
                                               else
                                                 menu_options.first
                                               end

                        Reservable::Staffs.run!(shop: shop, menu: shop.menus.find(selected_menu_option.id),
                                                business_time_range: reservation_time,
                                                number_of_customer: params[:customer_ids].size,
                                                reservation_id: reservation.try(:id))
                      else
                        []
                      end

      {
        category_menu_options: _category_with_menus[:category_with_menu_options],
        selected_menu_option: selected_menu_option,
        staff_options: staff_options,
        reservation: reservation
      }
    end
  end
end
