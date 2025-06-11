# frozen_string_literal: true

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
# Indexes
#
#  index_shop_menus_on_shop_id_and_menu_id  (shop_id,menu_id) UNIQUE
#

# max_seat_number is the maximum number of customers that can be seated at the shop for this menu,
# it is also kind of equivalent to the number of seats for the menu

class ShopMenu < ApplicationRecord
  default_value_for :max_seat_number, 1
  belongs_to :shop
  belongs_to :menu
  validates :max_seat_number, presence: true, numericality: { greater_than_or_equal_to: 0 }

  validates :menu_id, uniqueness: { scope: [:shop_id] }
end
