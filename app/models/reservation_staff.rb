# == Schema Information
#
# Table name: reservation_staffs
#
#  id             :integer          not null, primary key
#  reservation_id :integer          not null
#  staff_id       :integer          not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  state          :integer          default("pending")
#
# Indexes
#
#  index_reservation_staffs_on_reservation_id_and_staff_id  (reservation_id,staff_id) UNIQUE
#  state_by_staff_id_index                                  (staff_id,state)
#

class ReservationStaff < ApplicationRecord
  enum state: {
    pending: 0,
    accepted: 1
  }

  belongs_to :reservation
  belongs_to :staff

  def self.overlap_reservations(staff_ids: [], reservation_id: nil, start_time: , end_time:)
    ReservationStaff.joins(:reservation).
      where.not(reservation_id: reservation_id.presence).
      where("reservation_staffs.staff_id": staff_ids).
      where("reservations.start_time < ? and reservations.ready_time > ?", end_time, start_time)
  end
end
