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

class ShopMenuRepeatingDate < ApplicationRecord
  belongs_to :shop
  belongs_to :menu

  scope :future, -> { where("end_date > ?", Time.zone.now.to_date) }
end
