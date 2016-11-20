# == Schema Information
#
# Table name: menus
#
#  id                :integer          not null, primary key
#  user_id           :integer          not null
#  name              :string           not null
#  short_name        :string
#  minutes           :integer
#  interval          :integer
#  min_staffs_number :integer
#  max_seat_number   :integer
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#

class Menu < ApplicationRecord
  default_value_for :minutes, 60
  default_value_for :min_staffs_number, 1
  default_value_for :interval, 0

  validates :name, presence: true
  validates :minutes, presence: true
  validates :min_staffs_number, numericality: { greater_than: 0 }, allow_blank: true
  validates :max_seat_number, numericality: { greater_than: 0 }, allow_blank: true
  validates :short_name, length: { maximum: 15 }

  has_many :staff_menus, inverse_of: :menu, dependent: :destroy
  has_many :staffs, through: :staff_menus
  has_many :shop_menus, inverse_of: :menu, dependent: :destroy
  has_many :shops, through: :shop_menus
  has_many :menu_categories, dependent: :destroy
  has_many :categories, through: :menu_categories
  has_many :reservations
  belongs_to :user
  has_one :reservation_setting_menu, dependent: :destroy
  has_one :reservation_setting, through: :reservation_setting_menu
  has_one :menu_reservation_setting_rule, dependent: :destroy
  has_many :shop_menu_repeating_dates, dependent: :destroy

  accepts_nested_attributes_for :staff_menus, allow_destroy: true, reject_if: :reject_staffs

  private

  def reject_staffs(attributes)
    attributes["id"].blank? && attributes["staff_id"].blank?
  end
end
