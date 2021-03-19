# frozen_string_literal: true

class AddByStaffIdToReservations < ActiveRecord::Migration[5.1]
  def change
    add_column :reservations, :by_staff_id, :integer
  end
end
