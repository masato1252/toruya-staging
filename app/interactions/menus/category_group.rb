# frozen_string_literal: true

module Menus
  class CategoryGroup < ActiveInteraction::Base
    array :menu_options

    # [
    #  {:category => @category, :menus=>[@menu1, @menu2 ...]},
    # ]
    def execute
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
