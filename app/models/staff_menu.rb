# == Schema Information
#
# Table name: staff_menus
#
#  id         :integer          not null, primary key
#  staff_id   :integer          not null
#  menu_id    :integer          not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class StaffMenu < ApplicationRecord
  belongs_to :menu
  belongs_to :staff
end
