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
  default_value_for :minutes, 60
  default_value_for :min_staffs_number, 1

  validates :name, presence: true
  validates :minutes, presence: true
  validates :min_staffs_number, numericality: { greater_than: 0 }

  has_many :staff_menus, inverse_of: :menu
  has_many :staffs, through: :staff_menus
  has_many :reservation_settings
  has_many :reservations
  belongs_to :shop

  accepts_nested_attributes_for :staff_menus, allow_destroy: true
end
