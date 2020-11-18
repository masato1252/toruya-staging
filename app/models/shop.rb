# == Schema Information
#
# Table name: shops
#
#  id              :integer          not null, primary key
#  user_id         :integer
#  name            :string           not null
#  short_name      :string           not null
#  zip_code        :string           not null
#  phone_number    :string
#  email           :string
#  address         :string           not null
#  website         :string
#  holiday_working :boolean
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  deleted_at      :datetime
#
# Indexes
#
#  index_shops_on_user_id_and_deleted_at  (user_id,deleted_at)
#

class Shop < ApplicationRecord
  include ReservationChecking
  include Helpers

  validates :name, presence: true, format: { without: /\// }
  validates :short_name, presence: true
  validates :zip_code, presence: true
  validates :address, presence: true

  has_one_attached :logo
  has_many :staff_relations, class_name: "ShopStaff", dependent: :destroy
  has_many :shop_staffs, dependent: :destroy
  has_many :staffs, -> { active }, through: :shop_staffs
  has_many :shop_menus, dependent: :destroy
  has_many :menus, -> { active }, through: :shop_menus
  has_many :business_schedules
  has_many :custom_schedules
  has_many :reservations, -> { active }
  belongs_to :user

  scope :active, -> { where(deleted_at: nil) }
end
