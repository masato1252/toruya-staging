# == Schema Information
#
# Table name: reservations
#
#  id         :integer          not null, primary key
#  shop_id    :integer
#  menu_id    :integer
#  start_time :datetime
#  end_time   :datetime
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Reservation < ApplicationRecord
  belongs_to :shop
  belongs_to :menu
  has_many :reservation_staffs
  has_many :staffs, through: :reservation_staffs
  has_many :reservation_customers
  has_many :customers, through: :reservation_customers
end
