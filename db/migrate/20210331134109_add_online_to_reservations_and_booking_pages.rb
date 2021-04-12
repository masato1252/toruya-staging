class AddOnlineToReservationsAndBookingPages < ActiveRecord::Migration[5.2]
  def change
    add_column :menus, :online, :boolean, default: false
    add_column :reservations, :online, :boolean, default: false
  end
end
