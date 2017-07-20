# == Schema Information
#
# Table name: staffs
#
#  id                       :integer          not null, primary key
#  user_id                  :integer          not null
#  last_name                :string
#  first_name               :string
#  phonetic_last_name       :string
#  phonetic_first_name      :string
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  deleted_at               :datetime
#  staff_holiday_permission :boolean          default(FALSE), not null
#

class Staff < ApplicationRecord
  include NormalizeName
  include ReservationChecking

  belongs_to :user
  has_many :staff_menus, dependent: :destroy
  has_many :menus, through: :staff_menus
  has_many :shop_staffs, dependent: :destroy
  has_many :shops, through: :shop_staffs
  has_many :business_schedules, dependent: :destroy
  has_many :custom_schedules, dependent: :destroy
  has_many :reservation_staffs
  has_many :reservations, through: :reservation_staffs

  accepts_nested_attributes_for :staff_menus, allow_destroy: true

  validates :last_name, presence: true
  validates :first_name, presence: true
end
