# == Schema Information
#
# Table name: staffs
#
#  id         :integer          not null, primary key
#  user_id    :integer          not null
#  name       :string           not null
#  shortname  :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Staff < ApplicationRecord
  attr_accessor :first_name, :last_name, :first_shortname, :last_shortname

  validates :name, presence: true
  # validates :shortname, presence: true

  belongs_to :user
  has_many :staff_menus
  has_many :menus, through: :staff_menus
  has_many :shop_staffs
  has_many :shops, through: :shop_staffs
  has_many :business_schedules
  has_many :custom_schedules
  has_many :reservation_staffs
  has_many :reservations, through: :reservation_staffs

  accepts_nested_attributes_for :staff_menus, allow_destroy: true

  def last_name
    name.split(" ").first if name
  end

  def first_name
    name.split(" ").second if name
  end

  def last_shortname
    shortname.split(" ").first if shortname
  end

  def first_shortname
    shortname.split(" ").second if shortname
  end
end
