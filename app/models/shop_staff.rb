# == Schema Information
#
# Table name: shop_staffs
#
#  id                                     :integer          not null, primary key
#  shop_id                                :integer
#  staff_id                               :integer
#  created_at                             :datetime         not null
#  updated_at                             :datetime         not null
#  staff_regular_working_day_permission   :boolean          default(FALSE), not null
#  staff_temporary_working_day_permission :boolean          default(FALSE), not null
#

class ShopStaff < ApplicationRecord
  belongs_to :shop
  belongs_to :staff

  validates :staff_id, uniqueness: { scope: [:shop_id] }
end
