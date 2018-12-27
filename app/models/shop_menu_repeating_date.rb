# == Schema Information
#
# Table name: shop_menu_repeating_dates
#
#  id         :integer          not null, primary key
#  shop_id    :integer          not null
#  menu_id    :integer          not null
#  dates      :string           default([]), is an Array
#  end_date   :date
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_shop_menu_repeating_dates_on_menu_id              (menu_id)
#  index_shop_menu_repeating_dates_on_shop_id              (shop_id)
#  index_shop_menu_repeating_dates_on_shop_id_and_menu_id  (shop_id,menu_id) UNIQUE
#

class ShopMenuRepeatingDate < ApplicationRecord
  belongs_to :shop
  belongs_to :menu

  scope :future, -> { where("end_date > ?", Time.zone.now.to_date) }
end
