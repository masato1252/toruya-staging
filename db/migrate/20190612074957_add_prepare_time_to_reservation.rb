# frozen_string_literal: true

class AddPrepareTimeToReservation < ActiveRecord::Migration[5.2]
  def change
    add_column :reservations, :prepare_time, :datetime

    Reservation.find_each do |reservation|
      reservation.update_columns(prepare_time: reservation.start_time - reservation.menu.interval.to_i.minutes)
    end
  end
end
