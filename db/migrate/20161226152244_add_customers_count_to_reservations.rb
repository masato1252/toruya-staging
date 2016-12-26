class AddCustomersCountToReservations < ActiveRecord::Migration[5.0]
  def up
    add_column :reservations, :count_of_customers, :integer, default: 0

    Reservation.reset_column_information
    Reservation.pluck(:id).each do |p|
      Reservation.reset_counters p, :reservation_customers
    end
  end

  def down
    remove_column :reservations, :count_of_customers
  end
end
