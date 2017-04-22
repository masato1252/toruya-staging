# == Schema Information
#
# Table name: reservation_staffs
#
#  id             :integer          not null, primary key
#  reservation_id :integer          not null
#  staff_id       :integer          not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#

class ReservationStaff < ApplicationRecord
  belongs_to :reservation
  belongs_to :staff

  def self.overlap_reservations(staff_ids: [], reservation_id: nil, start_time: , end_time:)
    ReservationStaff.joins(:reservation).
      where.not(reservation_id: reservation_id.presence).
      where("reservation_staffs.staff_id": staff_ids).
      where("reservations.start_time < ? and reservations.ready_time > ?", end_time, start_time)
  end
end
