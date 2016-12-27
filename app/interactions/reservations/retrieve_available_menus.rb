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
      menu_options = shop.available_reservation_menus(reservation_time, params[:customer_ids].size, reservation.try(:id))

      _category_with_menus = category_with_menus(menu_options)

      menu_options = _category_with_menus[:menu_options]
      menu_ids = menu_options.map(&:id)

      staff_options = if menu_options.present?
                        selected_menu_option = if menu_ids.include?(params[:menu_id].to_i)
                                                 menu_options.find { |menu_option| menu_option.id == params[:menu_id].to_i }
                                               else
                                                 menu_options.first
                                               end

                        shop.available_staffs(shop.menus.find(selected_menu_option.id), reservation_time, params[:customer_ids].size, reservation.try(:id))
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

    private

    # [
    #  {:category => @category, :menus=>[@menu1, @menu2 ...]},
    # ]
    def category_with_menus(menu_options)
      # N + 1 query of category
      menu_ids = menu_options.map(&:id)
      all_menu_categories = MenuCategory.where(menu_id: menu_ids)
      all_cateogries = Category.where(id: all_menu_categories.map(&:category_id).uniq)
      all_menus_categories = []
      menu_option_categories = menu_options.map do |menu_option|
        _menu_categories = all_menu_categories.find_all { |menu_category| menu_category.menu_id == menu_option.id }
        _categories = all_cateogries.find_all { |category| _menu_categories.map(&:category_id).include?(category.id) }

        categories = _categories.map do |category|
          { category: category }
        end

        all_menus_categories << categories

        {
          menu_option: menu_option,
          categories: categories
        }
      end

      all_category_menus = []

      all_menu_categories = all_menus_categories.flatten.uniq.map do |category|
        _menu_options = menu_option_categories.map do |menu_option_category|
          if menu_option_category[:categories].any? { |category_hash| category_hash[:category] == category[:category] }
            menu_option_category[:menu_option]
          end
        end.compact

        all_category_menus << _menu_options
        category.merge(menu_options: _menu_options)
      end

      # When some menus doesn't have category, we just don't use any category
      if all_category_menus.flatten.uniq.size != menu_options.size
        {
          menu_options: menu_options,
          category_with_menu_options: menu_options
        }
      else
        {
          menu_options: menu_options,
          category_with_menu_options: all_menu_categories
        }
      end
    end
  end
end
