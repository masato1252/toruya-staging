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
#  full_time  :boolean
#

class Staff < ApplicationRecord
  attr_accessor :first_name, :last_name, :first_shortname, :last_shortname

  validates :name, presence: true
  validates :shortname, presence: true

  belongs_to :shop
  has_many :staff_menus
  has_many :menus, through: :staff_menus
  has_many :business_schedules
  has_many :custom_schedules

  accepts_nested_attributes_for :staff_menus, allow_destroy: true

  def last_name
    name.split(" ").first
  end

  def first_name
    name.split(" ").last
  end

  def last_shortname
    shortname.split(" ").first
  end

  def first_shortname
    shortname.split(" ").last
  end
end
