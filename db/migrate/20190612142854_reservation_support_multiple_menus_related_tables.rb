# frozen_string_literal: true

class ReservationSupportMultipleMenusRelatedTables < ActiveRecord::Migration[5.2]
  def change
    change_column :reservations, :menu_id, :integer, null: true

    create_table :reservation_booking_options do |t|
      t.references :reservation
      t.references :booking_option
    end

    create_table :reservation_menus do |t|
      t.references :reservation
      t.references :menu
      t.integer :position
    end

    add_index :reservation_menus, [:reservation_id, :menu_id], name: "reservation_menu_index"

    add_column :reservation_staffs, :menu_id, :integer
    add_column :reservation_staffs, :prepare_time, :datetime
    add_column :reservation_staffs, :work_start_at, :datetime
    add_column :reservation_staffs, :work_end_at, :datetime
    add_column :reservation_staffs, :ready_time, :datetime

    remove_index :reservation_staffs, name: :index_reservation_staffs_on_reservation_id_and_staff_id
    add_index :reservation_staffs, [:reservation_id, :menu_id, :staff_id, :reservation_id, :prepare_time, :work_start_at, :work_end_at, :ready_time], name: "reservation_staff_index"

    Reservation.find_each do |reservation|
      reservation.reservation_menus.find_or_create_by(menu_id: reservation.menu_id)
    end

    ReservationStaff.includes(:reservation).find_each do |reservation_staff|
      reservation = reservation_staff.reservation

      reservation_staff.update_columns(
        menu_id: reservation.menu_id,
        prepare_time: reservation.prepare_time,
        work_start_at: reservation.start_time,
        work_end_at: reservation.end_time,
        ready_time: reservation.ready_time
      )
    end
  end
end
