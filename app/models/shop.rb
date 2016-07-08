# == Schema Information
#
# Table name: shops
#
#  id           :integer          not null, primary key
#  user_id      :integer
#  name         :string
#  shortname    :string
#  zip_code     :string
#  phone_number :string
#  email        :string
#  website      :string
#  address      :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#

class Shop < ApplicationRecord
  validates :name, presence: true, uniqueness: { scope: :user_id }
  validates :shortname, presence: true, uniqueness: { scope: :user_id }
  validates :zip_code, presence: true
  validates :phone_number, presence: true
  validates :email, presence: true
  validates :address, presence: true

  has_many :staffs
end
