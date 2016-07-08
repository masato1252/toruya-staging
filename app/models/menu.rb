# == Schema Information
#
# Table name: menus
#
#  id                :integer          not null, primary key
#  shop_id           :integer          not null
#  name              :string           not null
#  shortname         :string
#  minutes           :integer
#  min_staffs_number :integer
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#

class Menu < ApplicationRecord
  validates :name, presence: true

  has_many :staff_menus
  has_many :staffs, through: :staff_menus

  accepts_nested_attributes_for :staff_menus, allow_destroy: true
end
