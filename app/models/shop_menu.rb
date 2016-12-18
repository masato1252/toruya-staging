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
  validates :max_seat_number, numericality: { greater_than: 0 }, allow_nil: true

  validates :menu_id, uniqueness: { scope: [:shop_id] }
end
