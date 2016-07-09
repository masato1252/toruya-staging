# == Schema Information
#
# Table name: staffs
#
#  id         :integer          not null, primary key
#  shop_id    :integer          not null
#  name       :string           not null
#  shortname  :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Staff < ApplicationRecord
  validates :name, presence: true
  validates :shortname, presence: true

  has_many :staff_menus
  has_many :menus, through: :staff_menus

  accepts_nested_attributes_for :staff_menus, allow_destroy: true
end
