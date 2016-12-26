# == Schema Information
#
# Table name: shop_menus
#
#  id              :integer          not null, primary key
#  shop_id         :integer
#  menu_id         :integer
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  max_seat_number :integer
#

class ShopMenu < ApplicationRecord
  belongs_to :shop
  belongs_to :menu
  validates :max_seat_number, presence: true, numericality: { greater_than_or_equal_to: 0 }

  validates :menu_id, uniqueness: { scope: [:shop_id] }
end
