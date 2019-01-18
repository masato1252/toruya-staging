# == Schema Information
#
# Table name: categories
#
#  id         :integer          not null, primary key
#  user_id    :integer
#  name       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_categories_on_user_id  (user_id)
#

class Category < ApplicationRecord
  has_many :menu_categories, dependent: :destroy
  has_many :menus, -> { active }, through: :menu_categories
  belongs_to :user

  validates :name, presence: true, uniqueness: { scope: [:user_id] }, length: { maximum: 15 }
end
