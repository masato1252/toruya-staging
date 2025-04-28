# frozen_string_literal: true

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
#  menu_id        :integer
#  prepare_time   :datetime
#  work_start_at  :datetime
#  work_end_at    :datetime
#  ready_time     :datetime
#
# Indexes
#
#  reservation_staff_index  (reservation_id,menu_id,staff_id,prepare_time,work_start_at,work_end_at,ready_time)
#  state_by_staff_id_index  (staff_id,state)
#

class ReservationStaff < ApplicationRecord
  PENDING_STATE = "pending"
  ACCEPTED_STATE = "accepted"

  enum state: {
    PENDING_STATE => 0,
    ACCEPTED_STATE => 1
  }

  belongs_to :reservation
  belongs_to :staff
  belongs_to :menu, required: false
  scope :order_by_menu_position, -> {
    joins("join reservation_menus ON reservation_menus.menu_id = reservation_staffs.menu_id AND
          reservation_menus.reservation_id = reservation_staffs.reservation_id").
          order("reservation_menus.position")
  }

  def self.overlap_reservations(staff_ids: [], reservation_id: nil, start_time: , end_time:)
    overlap_reservations_scope(staff_ids: staff_ids, reservation_id: reservation_id)
      .where("reservation_staffs.work_start_at < ? and reservation_staffs.ready_time > ?", end_time, start_time)
  end

  def self.overlap_reservations_scope(staff_ids: [], reservation_id: nil)
    ReservationStaff
      .joins(:reservation, :menu)
      .where.not(reservation_id: reservation_id.presence)
      .where.not("menus.min_staffs_number": 0)
      .where.not("reservations.aasm_state": "canceled")
      .where("reservation_staffs.staff_id": staff_ids)
      .where("reservations.deleted_at": nil)
  end
end