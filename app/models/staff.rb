# == Schema Information
#
# Table name: staffs
#
#  id            :integer          not null, primary key
#  user_id       :integer          not null
#  last_name     :string
#  first_name    :string
#  jp_last_name  :string
#  jp_first_name :string
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#

class Staff < ApplicationRecord
  belongs_to :user
  has_many :staff_menus
  has_many :menus, through: :staff_menus
  has_many :shop_staffs, dependent: :destroy
  has_many :shops, through: :shop_staffs
  has_many :business_schedules, dependent: :destroy
  has_many :custom_schedules, dependent: :destroy
  has_many :reservation_staffs, dependent: :destroy
  has_many :reservations, through: :reservation_staffs

  accepts_nested_attributes_for :staff_menus, allow_destroy: true

  def name
    "#{jp_last_name} #{jp_first_name}".presence || "#{first_name} #{last_name} "
  end
end
