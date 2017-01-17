# == Schema Information
#
# Table name: shops
#
#  id              :integer          not null, primary key
#  user_id         :integer
#  name            :string           not null
#  short_name      :string           not null
#  zip_code        :string           not null
#  phone_number    :string           not null
#  email           :string           not null
#  address         :string           not null
#  website         :string
#  holiday_working :boolean
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#

class Shop < ApplicationRecord
  include ReservationChecking

  validates :name, presence: true, uniqueness: { scope: :user_id }, format: { without: /\// }
  validates :short_name, presence: true, uniqueness: { scope: :user_id }
  validates :zip_code, presence: true
  validates :phone_number, presence: true
  validates :email, presence: true
  validates :address, presence: true

  has_many :shop_staffs, dependent: :destroy
  has_many :staffs, through: :shop_staffs
  has_many :shop_menus, dependent: :destroy
  has_many :menus, through: :shop_menus
  has_many :business_schedules
  has_many :custom_schedules
  has_many :customers
  has_many :reservations
  belongs_to :user
end
