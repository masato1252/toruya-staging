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
    end

    def execute
      reservation.attributes = params.slice(:start_time_date_part, :start_time_time_part, :end_time_time_part, :menu_id, :customer_ids) if reservation
      menus_scope = shop.available_reservation_menus(reservation_time, params[:customer_ids].size, reservation.try(:id))

      _category_with_menus = category_with_menus(menus_scope)

      menus = _category_with_menus[:menus]
      menu_ids = menus.map(&:id)

      staffs = if menus.present?
                 selected_menu = if menu_ids.include?(params[:menu_id].to_i)
                                   shop.menus.find_by(id: params[:menu_id])
                                 else
                                   menus.first
                                 end

                 shop.available_staffs(selected_menu, reservation_time, reservation.try(:id))
               else
                 []
               end

      {
        category_menus: _category_with_menus[:category_with_menus],
        selected_menu: selected_menu,
        staffs: staffs,
        reservation: reservation
      }
    end

    private

    # [
    #  {:category => @category, :menus=>[@menu1, @menu2 ...]},
    # ]
    def category_with_menus(menus_scope)
      menus = menus_scope.includes(:categories)
      menus = (menus + no_manpower_menus.includes(:categories)).uniq

      all_menu_categories = []
      menu_categories = menus.map do |menu|
        categories = menu.categories.map do |category|
          { category: category }
        end

        all_menu_categories << categories

        {
          menu: menu,
          categories: categories
        }
      end

      all_category_menus = []

      all_menu_categories = all_menu_categories.flatten.uniq.map do |category|
        _menus = menu_categories.map do |menu_category|
          if menu_category[:categories].any? { |category_hash| category_hash[:category] == category[:category] }
            menu_category[:menu]
          end
        end.compact

        all_category_menus << _menus
        category.merge(menus: _menus)
      end

      # When some menus doesn't have category, we just don't use any category
      if all_category_menus.flatten.uniq.size != menus.size
        {
          menus: menus,
          category_with_menus: menus
        }
      else
        {
          menus: menus,
          category_with_menus: all_menu_categories
        }
      end
    end

    def no_manpower_menus
      @no_manpower_menus ||= shop.no_manpower_menus(reservation_time)
    end
  end
end
