module Reservations
  class RetrieveAvailableMenus < ActiveInteraction::Base
    set_callback :type_check, :before do
      params[:staff_ids] = if params[:staff_ids].present?
                             params[:staff_ids].split(",").map{ |s| s if s.present? }.compact.uniq
                           elsif reservation
                             reservation.staff_ids
                           else
                             []
                           end

      params[:customer_ids] = if params[:customer_ids].present?
                             params[:customer_ids].split(",").map{ |c| c if c.present? }.compact.uniq
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
      menus_scope = shop.available_reservation_menus(reservation_time, params[:customer_ids].size, reservation.try(:id))
      menus = menus_scope.to_a
      menu_ids = menus.map(&:id)

      staffs = if menus_scope.exists?
                 selected_menu = if menu_ids.include?(params[:menu_id].to_i)
                                   shop.menus.find_by(id: params["menu_id"])
                                 elsif menu_ids.include?(reservation.try(:menu).try(:id))
                                   reservation.try(:menu)
                                 else
                                   menus.first
                                 end

                 shop.available_staffs(selected_menu, reservation_time, reservation.try(:id))
               else
                 []
               end

      {
        menus: menus, staffs: staffs, selected_menu: selected_menu, reservation: reservation,
        category_menus: category_with_menus(menus_scope)
      }
    end

    # [
    #  {:category => @category, :menus=>[@menu1, @menu2 ...]},
    #   ...
    # ]
    def category_with_menus(menus_scope)
      menus = menus_scope.includes(:categories)
      menu_categories = menus.map do |menu|
        categories = menu.categories.map do |category|
          { category: category }
        end

        {
          menu: menu,
          categories: categories
        }
      end

      all_menu_categories = menu_categories.map do |menu_category|
        menu_category[:categories]
      end.flatten.uniq

      all_menu_categories = all_menu_categories.map do |category|
        menus = menu_categories.map do |menu_category|
          if menu_category[:categories].any? { |category_hash| category_hash[:category] == category[:category] }
            menu_category[:menu]
          end
        end.compact

        category.merge(menus: menus)
      end

      # When some menus doesn't have category, we just don't use any category
      if all_menu_categories.map{|category| category[:menus] }.flatten.size != menus.size
        menus
      else
        all_menu_categories
      end
    end
  end
end
