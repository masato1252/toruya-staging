# == Schema Information
#
# Table name: staffs
#
#  id                  :integer          not null, primary key
#  user_id             :integer          not null
#  last_name           :string
#  first_name          :string
#  phonetic_last_name  :string
#  phonetic_first_name :string
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#

class Staff < ApplicationRecord
  include NormalizeName

  belongs_to :user
  has_many :staff_menus, dependent: :destroy
  has_many :menus, through: :staff_menus
  has_many :shop_staffs, dependent: :destroy
  has_many :shops, through: :shop_staffs
  has_many :business_schedules
  has_many :custom_schedules
  has_many :reservation_staffs, dependent: :destroy
  has_many :reservations, through: :reservation_staffs

  accepts_nested_attributes_for :staff_menus, allow_destroy: true

  validates :last_name, presence: true
  validates :first_name, presence: true
  validate :at_least_one_shop

  private

  def at_least_one_shop
    unless shop_staffs.exists?
      errors.add(:base, "Staff need to be at least one shop")
    end
  end
end
