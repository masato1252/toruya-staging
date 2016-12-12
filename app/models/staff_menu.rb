# == Schema Information
#
# Table name: staff_menus
#
#  id            :integer          not null, primary key
#  staff_id      :integer          not null
#  menu_id       :integer          not null
#  max_customers :integer
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#

class StaffMenu < ApplicationRecord
  default_value_for :max_customers, 1
  belongs_to :menu
  belongs_to :staff

  validate :valid_max_customers
  validates :staff_id, uniqueness: { scope: [:menu_id] }

  private

  def valid_max_customers
    if menu.min_staffs_number == 1
      if !max_customers || (max_customers && max_customers < 1)
        errors.add(:max_customers, "need specific max_customers number")
      end
    end
  end
end
