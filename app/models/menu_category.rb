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

class MenuCategory < ApplicationRecord
  belongs_to :menu
  belongs_to :category
end
