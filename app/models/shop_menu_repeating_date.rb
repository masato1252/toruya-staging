# == Schema Information
#
# Table name: shop_menu_repeating_dates
#
#  id         :integer          not null, primary key
#  shop_id    :integer
#  menu_id    :integer
#  dates      :string           default([]), is an Array
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class ShopMenuRepeatingDate < ApplicationRecord
  belongs_to :shop
  belongs_to :menu

  scope :future, -> { where("end_date > ?", Time.zone.now.to_date) }
end
