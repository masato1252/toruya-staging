# == Schema Information
#
# Table name: shop_staffs
#
#  id         :integer          not null, primary key
#  shop_id    :integer
#  staff_id   :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class ShopStaff < ApplicationRecord
  belongs_to :shop
  belongs_to :staff
end
