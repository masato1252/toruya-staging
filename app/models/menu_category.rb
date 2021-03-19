# frozen_string_literal: true

# == Schema Information
#
# Table name: menu_categories
#
#  id          :integer          not null, primary key
#  menu_id     :integer
#  category_id :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_menu_categories_on_menu_id_and_category_id  (menu_id,category_id)
#

class MenuCategory < ApplicationRecord
  belongs_to :menu
  belongs_to :category
end
