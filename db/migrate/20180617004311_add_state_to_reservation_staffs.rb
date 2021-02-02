# frozen_string_literal: true

class AddStateToReservationStaffs < ActiveRecord::Migration[5.1]
  def change
    add_column :reservation_staffs, :state, :integer, default: 0
    add_index :reservation_staffs, [:staff_id, :state], name: "state_by_staff_id_index"
  end
end
