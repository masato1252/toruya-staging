# frozen_string_literal: true

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
#  staff_full_time_permission             :boolean          default(FALSE), not null
#  level                                  :integer          default("staff"), not null
#
# Indexes
#
#  index_shop_staffs_on_shop_id_and_staff_id  (shop_id,staff_id) UNIQUE
#

class ShopStaff < ApplicationRecord
  belongs_to :shop
  belongs_to :staff

  validates :staff_id, uniqueness: { scope: [:shop_id] }

  enum level: {
    staff: 0,
    manager: 1
  }, _suffix: true
end
