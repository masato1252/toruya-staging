# == Schema Information
#
# Table name: categories
#
#  id         :integer          not null, primary key
#  user_id    :integer
#  name       :string
#  short_name :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Category < ApplicationRecord
  has_many :menu_categories, dependent: :destroy
  has_many :menus, through: :menu_categories
end
