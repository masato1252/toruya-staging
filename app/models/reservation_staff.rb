# == Schema Information
#
# Table name: reservation_staffs
#
#  id             :integer          not null, primary key
#  reservation_id :integer
#  staff_id       :integer
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#

class ReservationStaff < ApplicationRecord
  belongs_to :reservation
  belongs_to :staff
end
